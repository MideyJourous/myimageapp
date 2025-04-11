import os
import json
import requests
from datetime import datetime
from flask import Flask, request, jsonify, send_from_directory, send_file
import openai
import webbrowser
from threading import Timer

app = Flask(__name__, static_folder='../build')

# OpenAI API 키 설정
openai.api_key = os.environ.get('OPENAI_API_KEY')

# 이미지 저장 폴더
STORAGE_DIR = 'storage'
os.makedirs(STORAGE_DIR, exist_ok=True)
IMAGES_JSON_PATH = os.path.join(STORAGE_DIR, 'images.json')

# 이미지 데이터 저장 및 불러오기 함수
def load_images():
    if os.path.exists(IMAGES_JSON_PATH):
        with open(IMAGES_JSON_PATH, 'r', encoding='utf-8') as f:
            return json.load(f)
    return []

def save_images(images):
    with open(IMAGES_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(images, f, ensure_ascii=False, indent=2)

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
def save_image():
    try:
        data = request.json
        prompt = data.get('prompt', '')
        url = data.get('url', '')
        
        if not url or not prompt:
            return jsonify({"error": "URL과 설명이 필요합니다"}), 400
            
        images = load_images()
        image_id = str(int(datetime.now().timestamp() * 1000))
        
        new_image = {
            "id": image_id,
            "prompt": prompt,
            "imageUrl": url,
            "createdAt": datetime.now().isoformat()
        }
        
        images.insert(0, new_image)
        save_images(images)
        
        return jsonify(new_image)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/images/<image_id>', methods=['DELETE'])
def delete_image(image_id):
    try:
        images = load_images()
        images = [img for img in images if img['id'] != image_id]
        save_images(images)
        return jsonify({"success": True})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/images/clear', methods=['DELETE'])
def clear_images():
    try:
        save_images([])
        return jsonify({"success": True})
    except Exception as e:
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