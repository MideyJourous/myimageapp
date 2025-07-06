import os
import sys
import subprocess
import webbrowser
from threading import Timer
from flask import Flask, jsonify, request, send_from_directory
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from sqlalchemy.sql import func
import requests
import base64
import json
import uuid

app = Flask(__name__)

# 데이터베이스 설정
app.config["SQLALCHEMY_DATABASE_URI"] = os.environ.get("DATABASE_URL")
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
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
            'image_url': self.image_url,
            'model': self.model,
            'created_at': self.created_at.isoformat(),
        }

# 데이터베이스 테이블 생성
with app.app_context():
    db.create_all()

# 이미지 목록 불러오기
def load_images():
    images = Image.query.order_by(Image.created_at.desc()).all()
    return [image.to_dict() for image in images]

# 이미지 저장
def save_image(image_data):
    new_image = Image(
        id=image_data.get('id') or str(uuid.uuid4()),
        prompt=image_data.get('prompt', ''),
        image_url=image_data.get('image_url', ''),
        model=image_data.get('model', 'sdxl'),
    )
    db.session.add(new_image)
    db.session.commit()
    return new_image.to_dict()

# 한국어 프롬프트를 영어로 번역
def translate_prompt_to_english(korean_prompt):
    try:
        # 간단한 번역 API 사용 (실제로는 번역 서비스 사용 필요)
        response = requests.post(
            "https://translation.googleapis.com/language/translate/v2",
            params={"key": os.environ.get("GOOGLE_API_KEY", "")},
            data={
                "q": korean_prompt,
                "source": "ko",
                "target": "en",
                "format": "text"
            }
        )
        
        if response.status_code == 200:
            translated_text = response.json()["data"]["translations"][0]["translatedText"]
            return translated_text
        else:
            return korean_prompt
    except Exception as e:
        print(f"번역 오류: {e}")
        return korean_prompt

# TheHive AI를 사용한 이미지 생성
def generate_image_with_thehive(prompt, model="sdxl"):
    try:
        thehive_api_key = os.environ.get("THEHIVE_API_KEY")
        
        if not thehive_api_key:
            print("API 키 오류: API 키가 설정되지 않았습니다.")
            return {"error": "TheHive API 키가 설정되지 않았습니다."}
        
        # SDXL API 요청
        api_url = "https://api.thehive.ai/api/v2/stability/text-to-image"
            payload = {
                "prompt": prompt,
            "negative_prompt": "blurry, low quality, bad anatomy, worst quality, low resolution",
            "width": 1024,
            "height": 1024,
            "steps": 15,
            "guidance_scale": 3.5,
            "num_images": 1,
            "seed": -1
        }
        
        print(f"API 요청 URL: {api_url}")
        print(f"요청 페이로드: {json.dumps(payload, indent=2)}")
        
        # API 요청
        response = requests.post(
            api_url,
            headers={
                "Authorization": f"Bearer {thehive_api_key}",
                "Content-Type": "application/json"
            },
            json=payload
        )
        
        print(f"응답 상태 코드: {response.status_code}")
        print(f"응답 헤더: {response.headers}")
        print(f"응답 내용: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"파싱된 응답 데이터: {json.dumps(data, indent=2)}")
            
            if "images" in data and len(data["images"]) > 0:
                image_data = data["images"][0]
                if image_data:
                return {"image": image_data, "status": "success", "model": model}
                else:
                    print("이미지 데이터를 찾을 수 없음")
                    return {"error": "응답에서 이미지 데이터를 찾을 수 없습니다.", "data": data}
            else:
                print("유효하지 않은 응답 구조")
                return {"error": "이미지 생성 결과가 유효하지 않습니다.", "data": data}
        else:
            print(f"API 오류 응답: {response.status_code} - {response.text}")
            return {"error": f"API 요청 오류: {response.status_code} - {response.text}"}
    
    except Exception as e:
        print(f"예외 발생: {str(e)}")
        return {"error": f"이미지 생성 중 오류가 발생했습니다: {str(e)}"}

# API 엔드포인트
@app.route('/api/generate-image', methods=['POST'])
def generate_image():
    try:
        data = request.get_json()
        prompt = data.get('prompt', '')
        model = data.get('model', 'sdxl')
        
        if not prompt:
            return jsonify({"error": "Please enter a prompt."}), 400
        
        # Translate to English if in Korean (translation is handled in Flutter app)
        # english_prompt = translate_prompt_to_english(prompt) 
        
        # Generate image with TheHive API
        result = generate_image_with_thehive(prompt, model)
        
        if "error" in result:
            return jsonify({"error": result["error"]}), 500
        
        # Return Base64 image data
        return jsonify({
            "image": result["image"],
            "model": result["model"],
            "prompt": prompt
        })
    
    except Exception as e:
        return jsonify({"error": f"An error occurred while processing the request: {str(e)}"}), 500

# 이미지 목록 가져오기
@app.route('/api/images', methods=['GET'])
def get_images():
    try:
        images = load_images()
        return jsonify(images)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 이미지 저장 API
@app.route('/api/images', methods=['POST'])
def save_image_api():
    try:
        image_data = request.get_json()
        result = save_image(image_data)
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 이미지 삭제 API
@app.route('/api/images/<image_id>', methods=['DELETE'])
def delete_image(image_id):
    try:
        image = Image.query.get(image_id)
        if image:
            db.session.delete(image)
            db.session.commit()
            return jsonify({"success": True})
        else:
            return jsonify({"error": "이미지를 찾을 수 없습니다."}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 모든 이미지 삭제 API
@app.route('/api/images/clear', methods=['DELETE'])
def clear_images():
    try:
        Image.query.delete()
        db.session.commit()
        return jsonify({"success": True})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 정적 파일 서빙 (웹 버전용)
@app.route('/<path:path>')
def serve(path):
    import os
    web_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'web_version')
    return send_from_directory(web_dir, path)

@app.route('/')
def index():
    import os
    web_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'web_version')
    return send_from_directory(web_dir, 'index.html')

# 브라우저 자동 열기
def open_browser():
    webbrowser.open('http://localhost:5000')

# 메인 실행
if __name__ == '__main__':
    Timer(1, open_browser).start()
    app.run(host='0.0.0.0', port=5000, debug=True)