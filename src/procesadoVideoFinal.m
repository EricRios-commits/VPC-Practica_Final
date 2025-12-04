%% Leer un archivo de video, modificar, escribir en otro
videoHandleIn = VideoReader('ejemplo.mp4');        % de donde leeremos
videoHandleOut = VideoWriter('salida.avi');   % a donde escribiremos
videoHandleOut.Quality=95;
videoHandleOut.FrameRate = videoHandleIn.FrameRate; % heredamos el frame rate

open(videoHandleOut); % creamos realmente el fichero de salida

%%
frameBefore = readFrame(videoHandleIn);
[BW, xind, yind] = roipoly(frameBefore); % se pide al usuario que dibuje un poligono alrededor de la zona de interés
R = round(sqrt((max(xind)-min(xind))/2 + (max(yind)-min(yind))/2)); % calculamos automaticamente una gaussiana adecuada
D = 2*R+1; % lo doblamos y nos aseguramos de que sea impar
g = fspecial('gaussian', D, R/3);
BWfiltered = imfilter(double(BW), g);
frameBeforeROI = im2uint8(im2double(frameBefore).*BWfiltered);

roi = images.roi.Polygon;  % creamos el objeto ROI que luego necesitaremos para actualizar máscara y posición de la ROI
roi.Position = [xind, yind];

%%
pointsBefore = detectHarrisFeatures(rgb2gray(frameBeforeROI)); % Llamar a Harris limitándolo a que analice la imagen en la ROI, esto es, frameBeforeROI
[featuresBefore,validPointsBefore] = extractFeatures(rgb2gray(frameBeforeROI), pointsBefore); % extraer las características


%%
while hasFrame(videoHandleIn)  % mientras hayan frames que procesar
   frameNext = readFrame(videoHandleIn); % sacamos el frame actual como imagen
   
   frameNextROI = im2uint8(im2double(frameNext).*BWfiltered);
   pointsNext = detectHarrisFeatures(rgb2gray(frameNextROI)); % igual que linea 22 pero para el nuevo frame
   [featuresNext,validPointsNext] = extractFeatures(rgb2gray(frameNextROI), pointsNext); % igual que línea 23 pero para el nuevo frame

   indexPairs = matchFeatures(featuresBefore, featuresNext, 'Unique', true); % llamar a emparejamiento de características
   matchedPointsB = validPointsBefore(indexPairs(:,1)); % qué puntos de valid points before fueron emparejados
   matchedPointsN = validPointsNext(indexPairs(:,2)); % qué puntos de valid points next fueron emparejados
   if matchedPointsN.Count < 3 % si no tenemos suficientes para montar el modelo abortamos
       break;
   end

   showMatchedFeatures(frameBeforeROI,frameNextROI, matchedPointsB, matchedPointsN);
   imageCapture = getframe(gcf);
   legend('frame anterior','frame siguiente'); pause(1/videoHandleIn.FrameRate);
   
   tform = estimateGeometricTransform(matchedPointsB, matchedPointsN, 'projective'); % help estimateGeometricTransform
   [xind,yind] = transformPointsForward(tform, xind, yind); % help transformPoints ¿forward o inverse?

   roi.Position = [xind, yind];                    % actualizamos valores para... 
   BW = roi.createMask(rgb2gray(frameNext));     % comenzar un nuevo ciclo...
   BWfiltered = imfilter(double(BW), g);           % donde el frame actual pasar a ...
   frameBeforeROI = im2uint8(im2double(frameNext).*BWfiltered); % ser el frame anterior
   pointsBefore = pointsNext;
   featuresBefore = featuresNext;
   validPointsBefore = validPointsNext;

   writeVideo(videoHandleOut,imageCapture.cdata); % lo escribimos
end

close(videoHandleOut);  % cerramos el video que estamos creando