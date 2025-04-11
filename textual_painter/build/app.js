// 텍스트 이미지 생성기 - 자바스크립트

// 테마 프롬프트
const THEME_PROMPTS = {
    // 첫 번째 세트 (기본)
    'nature': '자연 풍경, 산과 숲, 아름다운 자연, 푸른 강, 맑은 하늘',
    'fantasy': '판타지 세계, 마법, 신비로운 생명체, 동화 같은 성, 마법의 숲',
    'abstract': '추상적인 패턴, 형태, 현대 예술, 생동감 있는 색상, 기하학적 패턴',
    'space': '우주, 별, 행성, 은하계, 성운, 우주 탐사, 심오한 우주',
    'cityscape': '도시 풍경, 건물, 야경, 도시 생활, 현대적 도시, 고층 건물',
    
    // 두 번째 세트 (추가)
    'portrait': '인물 사진, 자연스러운 포즈, 감정이 담긴 표정, 스튜디오 조명, 생생한 디테일',
    'food': '음식 사진, 맛있는 요리, 고급 레스토랑 음식, 신선한 재료, 아름다운 플레이팅',
    'animal': '동물 사진, 야생 동물, 귀여운 반려동물, 자연 서식지, 움직임이 담긴 순간',
    'ocean': '바다 풍경, 청록색 바다, 하얀 모래 해변, 파도, 열대 섬, 수중 생물',
    'art': '예술 작품, 클래식 미술, 유화 스타일, 미술관, 작품 전시, 예술적 질감'
};

// DOM 요소
const imageForm = document.getElementById('image-form');
const promptInput = document.getElementById('prompt');
const modelSelect = document.getElementById('model');
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

// 텍스트 디스플레이 UI 요소
const largeTextDisplay = document.getElementById('large-text-display');
const displayText = document.getElementById('display-text');

// 테마 관련 요소
const themeCards = document.querySelectorAll('.theme-card');

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
let savedImagesCache = null;

// 갤러리 및 구독 관련 DOM 요소
const galleryButton = document.getElementById('gallery-button');
const galleryOverlay = document.getElementById('gallery-overlay');
const closeGalleryButton = document.getElementById('close-gallery');
const subscriptionButton = document.getElementById('subscription-button');

// 초기화
document.addEventListener('DOMContentLoaded', () => {
    // 갤러리 버튼 클릭 시 갤러리 표시
    galleryButton.addEventListener('click', showGallery);
    
    // 갤러리 닫기 버튼 클릭 시 갤러리 숨기기
    closeGalleryButton.addEventListener('click', hideGallery);
    
    // 구독 버튼 클릭 시 이벤트 처리
    subscriptionButton.addEventListener('click', () => {
        showAlert('프리미엄 구독 기능은 준비 중입니다. 곧 만나볼 수 있습니다!', 'warning');
    });
    
    // 문자 수 카운터 업데이트 (텍스트 확대 효과 제거)
    promptInput.addEventListener('input', updateCharCount);
    
    // 이벤트 리스너 등록
    imageForm.addEventListener('submit', handleImageGeneration);
    saveBtn.addEventListener('click', saveCurrentImage);
    clearGalleryBtn.addEventListener('click', confirmClearGallery);
    
    // 테마 카드 선택 이벤트 등록
    themeCards.forEach(card => {
        card.addEventListener('click', () => {
            selectThemeCard(card);
        });
    });
    
    // 초기 문자 수 설정
    updateCharCount();
    
    // 서버에서 이미지 로드 및 로컬 스토리지와 동기화
    syncImagesWithServer().then(() => {
        // 랜덤 이미지 표시
        loadRandomImage();
    }).catch(() => {
        // 서버 오류시 로컬 이미지만 사용
        loadRandomImage();
    });
    
    // ESC 키를 눌러 갤러리 닫기
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && galleryOverlay.classList.contains('active')) {
            hideGallery();
        }
    });
    
    // 테마 카드 컨테이너 참조
    const themeCardsContainer = document.querySelector('.theme-cards-container');
    
    // 오류 해결을 위해 먼저 모든 변수 초기화
    window.isFirstCardSet = undefined; // 더 이상 사용하지 않는 변수 undefined로 설정
    
    // 드래그 스크롤 기능 완전히 다시 구현
    let isDragging = false;
    let startX, scrollLeft;
    
    // 마우스 이벤트 핸들러
    function onMouseDown(e) {
        isDragging = true;
        startX = e.pageX - themeCardsContainer.offsetLeft;
        scrollLeft = themeCardsContainer.scrollLeft;
        themeCardsContainer.style.cursor = 'grabbing';
    }
    
    function onMouseUp() {
        isDragging = false;
        themeCardsContainer.style.cursor = 'grab';
    }
    
    function onMouseLeave() {
        isDragging = false;
        themeCardsContainer.style.cursor = 'grab';
    }
    
    function onMouseMove(e) {
        if (!isDragging) return;
        e.preventDefault();
        const x = e.pageX - themeCardsContainer.offsetLeft;
        const walk = (x - startX) * 2; // 스크롤 속도 조정
        themeCardsContainer.scrollLeft = scrollLeft - walk;
    }
    
    // 터치 이벤트 핸들러
    function onTouchStart(e) {
        isDragging = true;
        startX = e.touches[0].pageX - themeCardsContainer.offsetLeft;
        scrollLeft = themeCardsContainer.scrollLeft;
    }
    
    function onTouchEnd() {
        isDragging = false;
    }
    
    function onTouchMove(e) {
        if (!isDragging) return;
        const x = e.touches[0].pageX - themeCardsContainer.offsetLeft;
        const walk = (x - startX) * 2;
        themeCardsContainer.scrollLeft = scrollLeft - walk;
    }
    
    // 이벤트 리스너 등록
    themeCardsContainer.addEventListener('mousedown', onMouseDown);
    themeCardsContainer.addEventListener('mouseup', onMouseUp);
    themeCardsContainer.addEventListener('mouseleave', onMouseLeave);
    themeCardsContainer.addEventListener('mousemove', onMouseMove);
    themeCardsContainer.addEventListener('touchstart', onTouchStart);
    themeCardsContainer.addEventListener('touchend', onTouchEnd);
    themeCardsContainer.addEventListener('touchmove', onTouchMove);
    
    // 모든 카드 표시 (블러 효과 포함)
    document.querySelectorAll('.theme-card').forEach(card => {
        card.style.display = 'inline-block';
    });
    
    // 스크롤 이벤트 애니메이션 효과
    function updateCardsOnScroll() {
        const scrollPosition = themeCardsContainer.scrollLeft;
        const containerCenter = themeCardsContainer.offsetWidth / 2;
        
        document.querySelectorAll('.theme-card').forEach(card => {
            // 카드의 중앙 위치 계산
            const cardLeft = card.offsetLeft;
            const cardCenter = cardLeft + (card.offsetWidth / 2);
            
            // 중앙으로부터의 거리 계산
            const distanceFromCenter = cardCenter - scrollPosition - containerCenter;
            const absDistance = Math.abs(distanceFromCenter);
            const maxDistance = containerCenter + (card.offsetWidth / 2);
            
            // 상대적 거리 (0~1 사이 값)
            const relativeDistance = Math.min(1, absDistance / maxDistance);
            
            // 스케일 계산 (중앙에 가까울수록 큰 스케일)
            const scale = Math.max(0.65, 1 - relativeDistance * 0.35);
            
            // Y축 위치 계산 (반원 형태로 만들기 위해)
            // 포물선 효과를 강화: y = a * x^2 (a는 강도 계수)
            const yOffset = Math.pow(relativeDistance, 2) * 80;
            
            // 회전 효과 (중앙에서 멀어질수록 기울어짐)
            // 부호에 따라 회전 방향 결정 (왼쪽/오른쪽)
            const rotate = (distanceFromCenter / maxDistance) * 20;
            
            // Z-index 설정 (중앙에 가까울수록 높은 z-index)
            const zIndex = Math.round(100 - relativeDistance * 50);
            card.style.zIndex = zIndex;
            
            // X축 약간 이동 (비대칭 효과 추가)
            // 중앙 카드는 움직이지 않고, 멀어질수록 약간 앞뒤로 이동
            const xOffset = Math.sign(distanceFromCenter) * Math.pow(relativeDistance, 1.5) * 10;
            
            // 효과 적용 (X/Y축 이동, 회전, 스케일)
            card.style.transform = `translateY(${yOffset}px) translateX(${xOffset}px) rotate(${rotate}deg) scale(${scale})`;
            
            // 중앙에서 멀수록 더 흐려지도록 불투명도 조정
            card.style.opacity = Math.max(0.6, 1 - relativeDistance * 0.4);
        });
    }
    
    // 초기 스크롤 위치 애니메이션 적용
    setTimeout(updateCardsOnScroll, 100);
    
    // 스크롤 이벤트에 애니메이션 효과 연결
    themeCardsContainer.addEventListener('scroll', () => {
        requestAnimationFrame(updateCardsOnScroll);
    });
});

// 서버와 로컬 스토리지 동기화
async function syncImagesWithServer() {
    try {
        // 서버에서 이미지 데이터 가져오기
        const response = await fetch('/api/images');
        
        if (!response.ok) {
            throw new Error('서버에서 이미지를 가져오는데 실패했습니다.');
        }
        
        const serverImages = await response.json();
        
        if (serverImages && serverImages.length > 0) {
            // 로컬 스토리지에 있는 이미지 가져오기
            let localImages = getSavedImages();
            
            // 서버 이미지 ID 목록
            const serverImageIds = new Set(serverImages.map(img => img.id));
            
            // 로컬 이미지 중 서버에 없는 이미지를 서버에 동기화
            for (const localImage of localImages) {
                if (!serverImageIds.has(localImage.id)) {
                    await saveToDatabaseAsync(localImage);
                }
            }
            
            // 로컬 스토리지의 이미지 ID 목록
            const localImageIds = new Set(localImages.map(img => img.id));
            
            // 서버에 있지만 로컬에 없는 이미지 추가
            for (const serverImage of serverImages) {
                if (!localImageIds.has(serverImage.id)) {
                    const newLocalImage = {
                        id: serverImage.id,
                        prompt: serverImage.prompt,
                        imageUrl: serverImage.image_url,
                        model: serverImage.model || 'sdxl',
                        createdAt: serverImage.created_at
                    };
                    
                    localImages.push(newLocalImage);
                }
            }
            
            // 날짜 기준으로 정렬
            localImages.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
            
            // 로컬 스토리지 업데이트
            localStorage.setItem(STORAGE_KEY, JSON.stringify(localImages));
            
            // 캐시 업데이트
            savedImagesCache = localImages;
        }
    } catch (error) {
        console.error('서버 동기화 오류:', error);
        // 오류 발생시 로컬 데이터만 사용
    }
}

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
    const selectedModel = modelSelect.value; // 선택된 모델 가져오기
    
    if (!prompt) {
        showError('이미지 설명을 입력해주세요.');
        return;
    }
    
    // UI 상태 업데이트
    generateBtn.disabled = true;
    loadingElement.classList.remove('d-none');
    errorElement.classList.add('d-none');
    resultElement.classList.add('d-none');
    
    // 텍스트 입력란에서 포커스 제거
    promptInput.blur();
    
    // 로딩 중 무지개 원 표시
    showFallbackCircle();
    
    try {
        // 선택된 모델 기반 로딩 메시지 업데이트
        const modelName = selectedModel === 'flux-schnell' ? 'Flux Schnell' : 'SDXL';
        loadingElement.querySelector('p').textContent = `${modelName} 모델로 이미지를 생성하고 있습니다. 잠시만 기다려주세요...`;
        
        // API 요청 - 선택된 모델 정보 포함
        const response = await fetch('/api/generate-image', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ 
                prompt,
                model: selectedModel  // 선택된 모델 전송
            })
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
            model: selectedModel, // 사용된 모델 저장
            createdAt: new Date().toISOString()
        };
        
        // 결과 영역에 이미지 표시
        generatedImage.src = data.url;
        downloadBtn.href = data.url;
        saveBtn.disabled = false;
        saveBtn.textContent = '갤러리에 저장';
        
        resultElement.classList.remove('d-none');
        
        // 상단 이미지 영역 코드 제거
        
    } catch (error) {
        showError(error);
        // 오류 발생 시 무지개 원 유지
    } finally {
        generateBtn.disabled = false;
        loadingElement.classList.add('d-none');
        // 기본 로딩 메시지로 복원
        loadingElement.querySelector('p').textContent = "이미지를 생성하고 있습니다. 잠시만 기다려주세요...";
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
    
    // 캐시 업데이트
    savedImagesCache = savedImages;
    
    // 알림 표시
    showAlert('이미지가 갤러리에 저장되었습니다.', 'success');
    
    // API 서버에 저장 요청 (로컬 스토리지와 별개의 백엔드 저장)
    saveToDatabaseAsync(currentImage);
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
    
    // 모델 정보 가져오기 (없으면 SDXL로 기본값 설정)
    const modelName = image.model ? 
                      (image.model === 'flux-schnell' ? 'Flux Schnell' : 'SDXL') : 
                      'SDXL';
    
    const card = document.createElement('div');
    card.className = 'card h-100 position-relative';
    card.innerHTML = `
        <img src="${image.imageUrl}" class="gallery-image" alt="${image.prompt}">
        <div class="gallery-caption">
            <h6>${image.prompt}</h6>
            <small>${formatDate(new Date(image.createdAt))}</small>
            <small class="d-block text-info">모델: ${modelName}</small>
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
    // 모델 정보 가져오기 (없으면 SDXL로 기본값 설정)
    const modelName = image.model ? 
                     (image.model === 'flux-schnell' ? 'Flux Schnell' : 'SDXL') : 
                     'SDXL';
    
    modalImage.src = image.imageUrl;
    modalPrompt.textContent = image.prompt;
    modalDate.textContent = `생성일: ${formatDate(new Date(image.createdAt))} | 모델: ${modelName}`;
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

// 데이터베이스에 이미지 저장 (백엔드 API 호출)
async function saveToDatabaseAsync(image) {
    try {
        const response = await fetch('/api/images', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                prompt: image.prompt,
                url: image.imageUrl,
                model: image.model
            })
        });
        
        if (!response.ok) {
            console.error('이미지를 서버에 저장하는 중 오류가 발생했습니다.');
        }
    } catch (error) {
        console.error('서버 저장 오류:', error);
    }
}

// 이미지 삭제
function deleteImage(imageId) {
    const savedImages = getSavedImages();
    const imageToDelete = savedImages.find(img => img.id === imageId);
    const updatedImages = savedImages.filter(img => img.id !== imageId);
    
    // 로컬 스토리지 업데이트
    localStorage.setItem(STORAGE_KEY, JSON.stringify(updatedImages));
    savedImagesCache = updatedImages;
    
    // 갤러리 다시 로드
    loadGalleryImages();
    
    // 상단 이미지 표시 관련 코드 제거
    
    // 서버에서도 삭제 요청 (백엔드 API가 있을 경우)
    if (imageToDelete) {
        deleteDatabaseImageAsync(imageId);
    }
    
    showAlert('이미지가 삭제되었습니다.', 'info');
}

// 데이터베이스에서 이미지 삭제 (백엔드 API 호출)
async function deleteDatabaseImageAsync(imageId) {
    try {
        const response = await fetch(`/api/images/${imageId}`, {
            method: 'DELETE'
        });
        
        if (!response.ok) {
            console.error('이미지를 서버에서 삭제하는 중 오류가 발생했습니다.');
        }
    } catch (error) {
        console.error('서버 삭제 오류:', error);
    }
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
    savedImagesCache = [];
    
    // 상단 이미지 초기화 코드 제거
    
    // 갤러리 UI 업데이트
    loadGalleryImages();
    
    // 서버에 초기화 요청
    clearDatabaseGalleryAsync();
    
    showAlert('갤러리가 초기화되었습니다.', 'info');
}

// 데이터베이스 갤러리 초기화 (백엔드 API 호출)
async function clearDatabaseGalleryAsync() {
    try {
        const response = await fetch('/api/images/clear', {
            method: 'DELETE'
        });
        
        if (!response.ok) {
            console.error('서버에서 모든 이미지를 삭제하는 중 오류가 발생했습니다.');
        }
    } catch (error) {
        console.error('서버 갤러리 초기화 오류:', error);
    }
}

// 날짜 포맷
function formatDate(date) {
    const options = { year: 'numeric', month: 'long', day: 'numeric' };
    return date.toLocaleDateString('ko-KR', options);
}

// 텍스트 입력 필드가 활성화될 때 호출되는 함수
function showLargeTextDisplay() {
    // 텍스트 표시 업데이트
    updateDisplayText();
    
    // 텍스트 디스플레이 표시
    largeTextDisplay.classList.remove('d-none');
    largeTextDisplay.classList.add('active');
    
    // 입력 변경 이벤트 추가
    promptInput.addEventListener('input', updateDisplayText);
}

// 텍스트 입력 필드가 비활성화될 때 호출되는 함수
function hideLargeTextDisplay() {
    // 텍스트 디스플레이 숨기기
    largeTextDisplay.classList.remove('active');
    setTimeout(() => {
        largeTextDisplay.classList.add('d-none');
    }, 300);
    
    // 입력 변경 이벤트 제거
    promptInput.removeEventListener('input', updateDisplayText);
}

// 대형 텍스트 디스플레이 업데이트
function updateDisplayText() {
    const text = promptInput.value.trim();
    displayText.textContent = text || '텍스트를 입력해주세요...';
}

// 랜덤 이미지 로드 함수
// 이미지 디스플레이 영역 삭제로 빈 함수로 대체
function loadRandomImage() {
    // 이미지 표시 영역이 제거되어 더 이상 필요 없음
    savedImagesCache = getSavedImages();
}

// 무지개 색상의 원 표시 기능 제거
function showFallbackCircle() {
    // 빈 함수로 유지 (호환성을 위해)
}

// 무지개 색상의 원 숨기기 기능 제거
function hideFallbackCircle() {
    // 빈 함수로 유지 (호환성을 위해)
}

// 갤러리 오버레이 표시
function showGallery() {
    // 갤러리 이미지 로드
    loadGalleryImages();
    
    // 갤러리 오버레이 표시
    galleryOverlay.style.display = 'block';
    // 약간의 지연 후 애니메이션 효과를 위해 active 클래스 추가
    setTimeout(() => {
        galleryOverlay.classList.add('active');
        // 스크롤 방지
        document.body.style.overflow = 'hidden';
    }, 10);
}

// 갤러리 오버레이 숨기기
function hideGallery() {
    // 애니메이션 제거
    galleryOverlay.classList.remove('active');
    
    // 트랜지션 후 완전히 숨기기
    setTimeout(() => {
        galleryOverlay.style.display = 'none';
        // 스크롤 다시 허용
        document.body.style.overflow = 'auto';
    }, 300);
}

// 테마 카드 선택
function selectThemeCard(card) {
    // 기존 선택된 카드의 active 클래스 제거
    themeCards.forEach(c => c.classList.remove('active'));
    
    // 선택된 카드에 active 클래스 추가
    card.classList.add('active');
    
    // 테마에 해당하는 프롬프트 가져오기
    const themeType = card.getAttribute('data-theme');
    const themePrompt = THEME_PROMPTS[themeType];
    
    // 프롬프트 입력창에 테마 프롬프트 설정
    promptInput.value = themePrompt;
    
    // 문자 수 카운터 업데이트
    updateCharCount();
    
    // 대형 텍스트 디스플레이 업데이트 제거
    
    // 알림 표시
    showAlert(`'${themeType}' 테마가 선택되었습니다.`, 'info');
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