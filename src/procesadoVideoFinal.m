%% Leer un archivo de video, modificar, escribir en otro
videoHandleIn = VideoReader('ejemplo.mp4');
videoHandleOut = VideoWriter('salida.avi');
videoHandleOut.Quality = 95;
videoHandleOut.FrameRate = videoHandleIn.FrameRate;
open(videoHandleOut);

%% Cargar el banner y su máscara
[banner, ~, banner_mask] = imread('banner.png');
% Si la máscara no viene con el PNG, créala (degradado horizontal como ejemplo)
if isempty(banner_mask)
    banner_mask = uint8(linspace(1, 255, size(banner, 2)));
    banner_mask = repmat(banner_mask, [size(banner, 1), 1]);
end

%% Inicialización de ROI
frameBefore = readFrame(videoHandleIn);
[BW, xind, yind] = roipoly(frameBefore);
R = round(sqrt((max(xind)-min(xind))/2 + (max(yind)-min(yind))/2));
D = 2*R+1;
g = fspecial('gaussian', D, R/3);
BWfiltered = imfilter(double(BW), g);
frameBeforeROI = im2uint8(im2double(frameBefore).*BWfiltered);
roi = images.roi.Polygon;
roi.Position = [xind, yind];

%% Detección inicial de características
pointsBefore = detectHarrisFeatures(rgb2gray(frameBeforeROI));
[featuresBefore, validPointsBefore] = extractFeatures(rgb2gray(frameBeforeROI), pointsBefore);

%% Procesamiento frame por frame
while hasFrame(videoHandleIn)
   frameNext = readFrame(videoHandleIn);
   frameNextROI = im2uint8(im2double(frameNext).*BWfiltered);
   
   % Detección en frame actual
   pointsNext = detectHarrisFeatures(rgb2gray(frameNextROI));
   [featuresNext, validPointsNext] = extractFeatures(rgb2gray(frameNextROI), pointsNext);
   
   % Emparejamiento
   indexPairs = matchFeatures(featuresBefore, featuresNext, 'Unique', true);
   matchedPointsB = validPointsBefore(indexPairs(:,1));
   matchedPointsN = validPointsNext(indexPairs(:,2));
   
   % Verificar suficientes puntos
   if matchedPointsN.Count < 4  % Mínimo 4 para proyectiva
       warning('Insuficientes puntos. Abortando.');
       break;
   end
   
   % Estimación de transformación
   tform = estimateGeometricTransform(matchedPointsB, matchedPointsN, 'projective');
   [xind, yind] = transformPointsForward(tform, xind, yind);
   
   % Calcular el centro de la ROI para posicionar el banner
   centerX = round(mean(xind));
   centerY = round(mean(yind));
   
   % Calcular posición superior-izquierda del banner (centrado en la ROI)
   bannerX = centerX - round(size(banner, 2)/2);
   bannerY = centerY - round(size(banner, 1)/2);
   
   % Aplicar el banner al frame
   frameWithBanner = maskBanner(frameNext, banner, banner_mask, bannerX, bannerY);
   
   % Visualización (opcional: mostrar con banner o sin banner)
   showMatchedFeatures(frameBeforeROI, frameNextROI, matchedPointsB, matchedPointsN);
   imageCapture = getframe(gcf);
   legend('frame anterior', 'frame siguiente'); 
   pause(1/videoHandleIn.FrameRate);
   
   % Actualizar máscara para siguiente iteración
   roi.Position = [xind, yind];
   BW = roi.createMask(rgb2gray(frameNext));
   BWfiltered = imfilter(double(BW), g);
   frameBeforeROI = im2uint8(im2double(frameNext).*BWfiltered);
   
   % Actualizar características
   pointsBefore = pointsNext;
   featuresBefore = featuresNext;
   validPointsBefore = validPointsNext;
   
   % Escribir el frame CON el banner (no la visualización de matching)
   writeVideo(videoHandleOut, frameWithBanner);
end

close(videoHandleOut);