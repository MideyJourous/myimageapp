import os
import json
import requests
import base64
from datetime import datetime
from flask import Flask, request, jsonify, send_from_directory, send_file
import webbrowser
from threading import Timer
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.sql import func
from dotenv import load_dotenv

# .env 파일 로드
load_dotenv()

app = Flask(__name__, static_folder='../build')

# 데이터베이스 설정
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)


# 이미지 모델 정의
class Image(db.Model):
    __tablename__ = 'images'

    id = db.Column(db.String(50), primary_key=True)
    prompt = db.Column(db.Text, nullable=False)
    image_url = db.Column(db.String(500), nullable=False)
    model = db.Column(db.String(50), nullable=True)  # 'sdxl' 또는 'flux-schnell'
    created_at = db.Column(db.DateTime(timezone=True),
                           server_default=func.now())

    def to_dict(self):
        return {
            'id': self.id,
            'prompt': self.prompt,
            'imageUrl': self.image_url,
            'model': self.model or 'sdxl',  # 없으면 기본값 'sdxl'
            'createdAt': self.created_at.isoformat()
        }


# 데이터베이스 테이블 생성
with app.app_context():
    db.create_all()

# TheHive.AI API 키 설정
THEHIVE_API_KEY = os.environ.get('THEHIVE_API_KEY')

# TheHive.AI API 설정 - v3 API 사용
THEHIVE_API_URL = "https://api.thehive.ai/api/v3/hive/sdxl-enhanced"
THEHIVE_FLUX_API_URL = "https://api.thehive.ai/api/v3/hive/flux-schnell"


# 이미지 데이터 저장 및 불러오기 함수
def load_images():
    images = Image.query.order_by(Image.created_at.desc()).all()
    return [image.to_dict() for image in images]


def save_image(image_data):
    image = Image(
        id=image_data['id'],
        prompt=image_data['prompt'],
        image_url=image_data['imageUrl'],
        model=image_data.get('model', 'sdxl')  # 모델 정보 저장 (기본값: sdxl)
    )
    db.session.add(image)
    db.session.commit()
    return image.to_dict()


# TheHive.AI API를 사용하여 이미지 생성
def generate_image_with_thehive(prompt, model="sdxl"):
    try:
        print(f"Using TheHive.AI API for image generation with model: {model}")

        # API 요청 헤더 설정 - Bearer 인증 방식 사용
        headers = {
            "authorization": f"Bearer {THEHIVE_API_KEY}",
            "Content-Type": "application/json"
        }

        # 모델 선택 및 API 엔드포인트 결정
        api_url = THEHIVE_API_URL
        if model.lower() == "flux-schnell":
            api_url = THEHIVE_FLUX_API_URL

        # 새로운 API v3 형식에 맞게 요청 데이터 구성
        data = {
            "input": {
                "prompt": prompt,
                "negative_prompt": "",
                "image_size": {"width": 1024, "height": 1024},
                "num_inference_steps": 15,
                "guidance_scale": 3.5,
                "num_images": 1,
                "output_format": "png"
            }
        }

        # API 요청
        response = requests.post(api_url, headers=headers, json=data)

        # 상태 코드 확인
        if response.status_code != 200:
            error_message = f"TheHive.AI API Error: {response.status_code} - {response.text}"
            print(error_message)
            return None, error_message, response.status_code

        # 응답 파싱
        result = response.json()
        print(f"API 응답: {result}")

        # 이미지 URL 또는 데이터 추출
        try:
            # v3 API 응답 형식에 맞게 파싱
            if "output" in result:
                outputs = result["output"]
                if isinstance(outputs, list) and len(outputs) > 0:
                    # base64 이미지 데이터를 URL 형식으로 변환
                    if "image_b64" in outputs[0]:
                        image_url = f"data:image/png;base64,{outputs[0]['image_b64']}"
                        return image_url, None, 200
                    # URL이 있는 경우 (키가 'url'일 수도 있고 'image_url'일 수도 있음)
                    elif "url" in outputs[0]:
                        image_url = outputs[0]["url"]
                        return image_url, None, 200
                    elif "image_url" in outputs[0]:
                        image_url = outputs[0]["image_url"]
                        return image_url, None, 200

            # 파싱 실패시 자세한 오류 메시지 반환
            print(f"응답 파싱 실패: {result}")
            return None, "응답에서 이미지 URL을 찾을 수 없습니다 (응답 형식 다름)", 500

        except (KeyError, IndexError) as e:
            print(f"응답 파싱 중 오류: {e}, 응답: {result}")
            return None, f"응답에서 이미지 URL을 찾을 수 없습니다: {str(e)}", 500

    except Exception as e:
        error_message = f"TheHive.AI API 호출 중 오류: {str(e)}"
        print(error_message)
        return None, error_message, 500


# API 라우트
@app.route('/api/generate-image', methods=['POST'])
def generate_image():
    try:
        data = request.json
        prompt = data.get('prompt', '')

        # 클라이언트에서 전송한 모델 정보 수신 (기본값: sdxl)
        selected_model = data.get('model', 'sdxl')

        # 허용된 모델 확인 (sdxl 또는 flux-schnell만 허용)
        if selected_model not in ['sdxl', 'flux-schnell']:
            selected_model = 'sdxl'  # 유효하지 않으면 기본값 사용

        if not prompt:
            return jsonify({"error": "텍스트 설명이 필요합니다"}), 400

        # TheHive.AI API를 사용하여 이미지 생성
        try:
            print(
                f"Generating image with model: {selected_model}, prompt: '{prompt}'"
            )

            # TheHive.AI API로 이미지 생성
            image_url, error, status_code = generate_image_with_thehive(
                prompt, selected_model)

            if error:
                return jsonify({"error": error}), status_code

            return jsonify({"url": image_url})

        except Exception as api_err:
            # API 특정 오류 처리
            error_message = str(api_err)
            error_code = 500

            print(f"TheHive.AI API Error: {error_message}")
            return jsonify({
                "error": error_message,
                "detail": str(api_err)
            }), error_code

    except Exception as e:
        print(f"Error generating image: {e}")
        return jsonify({
            "error": "이미지 생성 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.",
            "detail": str(e)
        }), 500


@app.route('/api/images', methods=['GET'])
def get_images():
    try:
        images = load_images()
        return jsonify(images)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/images', methods=['POST'])
def save_image_api():
    try:
        data = request.json
        prompt = data.get('prompt', '')
        url = data.get('url', '')
        model = data.get('model', 'sdxl')  # 모델 정보 가져오기

        if not url or not prompt:
            return jsonify({"error": "URL과 설명이 필요합니다"}), 400

        image_id = str(int(datetime.now().timestamp() * 1000))

        new_image = {
            "id": image_id,
            "prompt": prompt,
            "imageUrl": url,
            "model": model,  # 모델 정보 추가
            "createdAt": datetime.now().isoformat()
        }

        # 데이터베이스에 저장
        saved_image = save_image(new_image)

        return jsonify(saved_image)
    except Exception as e:
        print(f"Error saving image: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/images/<image_id>', methods=['DELETE'])
def delete_image(image_id):
    try:
        # 데이터베이스에서 이미지 삭제
        image = Image.query.get(image_id)
        if image:
            db.session.delete(image)
            db.session.commit()
            return jsonify({"success": True})
        else:
            return jsonify({"error": "이미지를 찾을 수 없습니다"}), 404
    except Exception as e:
        print(f"Error deleting image: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/images/clear', methods=['DELETE'])
def clear_images():
    try:
        # 모든 이미지 삭제
        db.session.query(Image).delete()
        db.session.commit()
        return jsonify({"success": True})
    except Exception as e:
        print(f"Error clearing images: {e}")
        return jsonify({"error": str(e)}), 500


# React 앱 서빙
@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def serve(path):
    if path and os.path.exists(os.path.join(app.static_folder, path)):
        return send_from_directory(app.static_folder, path)
    return send_file(os.path.join(app.static_folder, 'index.html'))


def open_browser():
    webbrowser.open('http://localhost:5000')


if __name__ == '__main__':
    # 브라우저 자동 열기
    Timer(1, open_browser).start()
    # 서버 시작
    app.run(host='0.0.0.0', port=5000, debug=True)
