import os
import json
import requests
from datetime import datetime
from flask import Flask, request, jsonify, send_from_directory, send_file
import openai
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
    created_at = db.Column(db.DateTime(timezone=True), server_default=func.now())
    
    def to_dict(self):
        return {
            'id': self.id,
            'prompt': self.prompt,
            'imageUrl': self.image_url,
            'createdAt': self.created_at.isoformat()
        }

# 데이터베이스 테이블 생성
with app.app_context():
    db.create_all()

# OpenAI API 키 설정
openai.api_key = os.environ.get('OPENAI_API_KEY')

# 이미지 데이터 저장 및 불러오기 함수
def load_images():
    images = Image.query.order_by(Image.created_at.desc()).all()
    return [image.to_dict() for image in images]

def save_image(image_data):
    image = Image(
        id=image_data['id'],
        prompt=image_data['prompt'],
        image_url=image_data['imageUrl']
    )
    db.session.add(image)
    db.session.commit()
    return image.to_dict()

# API 라우트
@app.route('/api/generate-image', methods=['POST'])
def generate_image():
    try:
        data = request.json
        prompt = data.get('prompt', '')
        
        if not prompt:
            return jsonify({"error": "텍스트 설명이 필요합니다"}), 400
            
        # OpenAI API를 사용하여 이미지 생성
        try:
            response = openai.images.generate(
                model="dall-e-3",
                prompt=prompt,
                n=1,
                size="1024x1024",
                quality="standard"
            )
            
            image_url = response.data[0].url
            
            return jsonify({"url": image_url})
        except openai.APIError as api_err:
            # OpenAI API 특정 오류 처리
            error_message = str(api_err)
            error_code = 500
            
            if "billing_hard_limit_reached" in error_message:
                error_message = "API 사용량 한도에 도달했습니다. 관리자에게 문의하거나 잠시 후 다시 시도해주세요."
                error_code = 402  # Payment Required
            elif "rate_limit_exceeded" in error_message:
                error_message = "API 요청 한도를 초과했습니다. 잠시 후 다시 시도해주세요."
                error_code = 429  # Too Many Requests
            
            print(f"OpenAI API Error: {error_message}")
            return jsonify({"error": error_message, "detail": str(api_err)}), error_code
            
    except Exception as e:
        print(f"Error generating image: {e}")
        return jsonify({"error": "이미지 생성 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.", "detail": str(e)}), 500

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
        
        if not url or not prompt:
            return jsonify({"error": "URL과 설명이 필요합니다"}), 400
            
        image_id = str(int(datetime.now().timestamp() * 1000))
        
        new_image = {
            "id": image_id,
            "prompt": prompt,
            "imageUrl": url,
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