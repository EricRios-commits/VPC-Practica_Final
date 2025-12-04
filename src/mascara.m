%% Ejemplo de cómo fusionar con una máscara de transparencia un banner b a color con una imagen I a partir de las coordeadas (yc, xc)
% Creamos una imagen a gris medio y un banner de color aleatorio
I = ones(256, 256, 3, "uint8")*128;
b = randi(255, 50*100*3, 1, "uint8");
b = reshape(b, 50, 100, 3);
% creamos una máscara degradado lineal en horizontal
b_mask = uint8(linspace(1, 255, 100));
b_mask = repmat(b_mask, [50 1]);

% en su código b y la máscara se cargan de disco: [b, ~, b_mask] = imread("banner.png"); Se pasan a double tras cargarse
b = im2double(b);
b_mask = im2double(b_mask);

% dentro del bucle de seguimiento se calcula el centro de la máscara en cada iteración
xc = 10; yc = 15;

% éste es el código para realizar la fusión: foreground*alpha + background*(1-alpha), pero con los detalles necesarios
rx = [1:size(b, 2)]-1; ry = [1:size(b, 1)]-1;
fondo = im2double(I(yc +ry, xc + rx, :));
for c=1:3
    fondo(:,:,c) = b(:,:,c).*b_mask + fondo(:,:,c).*(1-b_mask);
end
I(yc +ry, xc + rx, :) = im2uint8(fondo);

imshow(I)
