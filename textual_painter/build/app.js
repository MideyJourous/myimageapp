// 텍스트 이미지 생성기 - 자바스크립트

// DOM 요소
const imageForm = document.getElementById('image-form');
const promptInput = document.getElementById('prompt');
const charCount = document.getElementById('char-count');
const generateBtn = document.getElementById('generate-btn');
const loadingElement = document.getElementById('loading');
const errorElement = document.getElementById('error');
const resultElement = document.getElementById('result');
const generatedImage = document.getElementById('generated-image');
const saveBtn = document.getElementById('save-btn');
const downloadBtn = document.getElementById('download-btn');
const galleryContainer = document.getElementById('gallery-container');
const emptyGallery = document.getElementById('empty-gallery');
const clearGalleryBtn = document.getElementById('clear-gallery');

// 모달 요소
const imageModal = new bootstrap.Modal(document.getElementById('image-modal'));
const modalImage = document.getElementById('modal-image');
const modalPrompt = document.getElementById('modal-prompt');
const modalDate = document.getElementById('modal-date');
const modalDownload = document.getElementById('modal-download');
const modalDelete = document.getElementById('modal-delete');

const confirmModal = new bootstrap.Modal(document.getElementById('confirm-modal'));
const confirmTitle = document.getElementById('confirm-title');
const confirmMessage = document.getElementById('confirm-message');
const confirmButton = document.getElementById('confirm-button');

// 상수
const MAX_PROMPT_LENGTH = 1000;
const STORAGE_KEY = 'text_to_image_gallery';

// 현재 생성된 이미지 데이터
let currentImage = null;

// 초기화
document.addEventListener('DOMContentLoaded', () => {
    // 갤러리 탭 클릭 시 이미지 로드
    document.getElementById('gallery-tab').addEventListener('click', loadGalleryImages);
    
    // 문자 수 카운터 업데이트
    promptInput.addEventListener('input', updateCharCount);
    
    // 이벤트 리스너 등록
    imageForm.addEventListener('submit', handleImageGeneration);
    saveBtn.addEventListener('click', saveCurrentImage);
    clearGalleryBtn.addEventListener('click', confirmClearGallery);
    
    // 초기 문자 수 설정
    updateCharCount();
});

// 문자 수 업데이트
function updateCharCount() {
    const currentLength = promptInput.value.length;
    charCount.textContent = `${currentLength}/${MAX_PROMPT_LENGTH}`;
    
    // 글자 수가 너무 많으면 카운터 색상 변경
    if (currentLength > MAX_PROMPT_LENGTH * 0.9) {
        charCount.classList.add('text-danger');
    } else {
        charCount.classList.remove('text-danger');
    }
}

// 이미지 생성 처리
async function handleImageGeneration(e) {
    e.preventDefault();
    
    const prompt = promptInput.value.trim();
    if (!prompt) {
        showError('이미지 설명을 입력해주세요.');
        return;
    }
    
    // UI 상태 업데이트
    generateBtn.disabled = true;
    loadingElement.classList.remove('d-none');
    errorElement.classList.add('d-none');
    resultElement.classList.add('d-none');
    
    try {
        // API 요청
        const response = await fetch('/api/generate-image', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ prompt })
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            throw data; // 오류 객체를 그대로 전달
        }
        
        // 생성된 이미지 표시
        currentImage = {
            id: Date.now().toString(),
            prompt,
            imageUrl: data.url,
            createdAt: new Date().toISOString()
        };
        
        generatedImage.src = data.url;
        downloadBtn.href = data.url;
        saveBtn.disabled = false;
        saveBtn.textContent = '갤러리에 저장';
        
        resultElement.classList.remove('d-none');
        
    } catch (error) {
        showError(error);
    } finally {
        generateBtn.disabled = false;
        loadingElement.classList.add('d-none');
    }
}

// 오류 메시지 표시
function showError(message) {
    // 오류 세부 정보가 있으면 처리
    if (typeof message === 'object' && message.error) {
        const errorDetail = message.detail ? `<br><small class="text-muted">${message.detail}</small>` : '';
        errorElement.innerHTML = `${message.error}${errorDetail}`;
    } else {
        errorElement.textContent = message;
    }
    
    errorElement.classList.remove('d-none');
}

// 현재 이미지 저장
function saveCurrentImage() {
    if (!currentImage) return;
    
    // 저장된 이미지 목록 가져오기
    const savedImages = getSavedImages();
    
    // 현재 이미지 추가
    savedImages.unshift(currentImage);
    
    // 저장
    localStorage.setItem(STORAGE_KEY, JSON.stringify(savedImages));
    
    // 저장 버튼 비활성화
    saveBtn.disabled = true;
    saveBtn.textContent = '저장됨';
    
    // 알림 표시
    showAlert('이미지가 갤러리에 저장되었습니다.', 'success');
}

// 저장된 이미지 목록 가져오기
function getSavedImages() {
    const imagesJson = localStorage.getItem(STORAGE_KEY);
    return imagesJson ? JSON.parse(imagesJson) : [];
}

// 갤러리 이미지 로드
function loadGalleryImages() {
    const savedImages = getSavedImages();
    
    // 갤러리 컨테이너 초기화
    galleryContainer.innerHTML = '';
    
    // 이미지가 있는지 확인
    if (savedImages.length > 0) {
        emptyGallery.style.display = 'none';
        galleryContainer.style.display = 'flex';
        clearGalleryBtn.style.display = 'block';
        
        // 이미지 카드 생성
        savedImages.forEach(image => {
            const imageCard = createImageCard(image);
            galleryContainer.appendChild(imageCard);
        });
    } else {
        emptyGallery.style.display = 'flex';
        galleryContainer.style.display = 'none';
        clearGalleryBtn.style.display = 'none';
    }
}

// 이미지 카드 생성
function createImageCard(image) {
    const col = document.createElement('div');
    col.className = 'col';
    
    const card = document.createElement('div');
    card.className = 'card h-100 position-relative';
    card.innerHTML = `
        <img src="${image.imageUrl}" class="gallery-image" alt="${image.prompt}">
        <div class="gallery-caption">
            <h6>${image.prompt}</h6>
            <small>${formatDate(new Date(image.createdAt))}</small>
        </div>
    `;
    
    // 이미지 클릭 시 모달 표시
    card.addEventListener('click', () => {
        showImageDetails(image);
    });
    
    col.appendChild(card);
    return col;
}

// 이미지 상세 정보 모달 표시
function showImageDetails(image) {
    modalImage.src = image.imageUrl;
    modalPrompt.textContent = image.prompt;
    modalDate.textContent = `생성일: ${formatDate(new Date(image.createdAt))}`;
    modalDownload.href = image.imageUrl;
    modalDelete.dataset.id = image.id;
    
    // 삭제 버튼 이벤트 리스너
    modalDelete.onclick = () => {
        imageModal.hide();
        confirmDeleteImage(image.id);
    };
    
    imageModal.show();
}

// 이미지 삭제 확인
function confirmDeleteImage(imageId) {
    // 모달 제목과 메시지 설정
    confirmTitle.textContent = '이미지 삭제';
    confirmMessage.textContent = '이 이미지를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
    
    // 확인 버튼 클릭 시 이벤트
    confirmButton.onclick = () => {
        deleteImage(imageId);
        confirmModal.hide();
    };
    
    // 모달 표시
    confirmModal.show();
}

// 이미지 삭제
function deleteImage(imageId) {
    const savedImages = getSavedImages();
    const updatedImages = savedImages.filter(img => img.id !== imageId);
    
    localStorage.setItem(STORAGE_KEY, JSON.stringify(updatedImages));
    loadGalleryImages();
    
    showAlert('이미지가 삭제되었습니다.', 'info');
}

// 갤러리 초기화 확인
function confirmClearGallery() {
    confirmTitle.textContent = '갤러리 초기화';
    confirmMessage.textContent = '갤러리의 모든 이미지를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
    
    confirmButton.onclick = () => {
        clearGallery();
        confirmModal.hide();
    };
    
    confirmModal.show();
}

// 갤러리 초기화
function clearGallery() {
    localStorage.removeItem(STORAGE_KEY);
    loadGalleryImages();
    
    showAlert('갤러리가 초기화되었습니다.', 'info');
}

// 날짜 포맷
function formatDate(date) {
    const options = { year: 'numeric', month: 'long', day: 'numeric' };
    return date.toLocaleDateString('ko-KR', options);
}

// 알림 표시
function showAlert(message, type = 'info') {
    // Bootstrap toast 생성
    const toastContainer = document.createElement('div');
    toastContainer.className = 'toast-container position-fixed bottom-0 end-0 p-3';
    
    const toast = document.createElement('div');
    toast.className = `toast align-items-center text-white bg-${type} border-0`;
    toast.setAttribute('role', 'alert');
    toast.setAttribute('aria-live', 'assertive');
    toast.setAttribute('aria-atomic', 'true');
    
    toast.innerHTML = `
        <div class="d-flex">
            <div class="toast-body">
                ${message}
            </div>
            <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
        </div>
    `;
    
    toastContainer.appendChild(toast);
    document.body.appendChild(toastContainer);
    
    const bsToast = new bootstrap.Toast(toast, { delay: 3000 });
    bsToast.show();
    
    // 토스트가 사라진 후 컨테이너 제거
    toast.addEventListener('hidden.bs.toast', () => {
        document.body.removeChild(toastContainer);
    });
}