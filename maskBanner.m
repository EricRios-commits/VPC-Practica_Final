function frame=maskBanner(frame, banner, positionX, positionY)
    % banner = reshape(banner, 50, 100, 3);
    % creamos una máscara degradado lineal en horizontal
    b_mask = uint8(linspace(1, 255, 100));
    b_mask = repmat(b_mask, [50 1]);
    banner = im2double(banner);
    b_mask = im2double(b_mask);
    rx = [1:size(banner, 2)]-1; 
    ry = [1:size(banner, 1)]-1;
    fondo = im2double(frame(positionY +ry, positionX + rx, :));
    for c=1:3
        fondo(:,:,c) = b(:,:,c).*b_mask + fondo(:,:,c).*(1-b_mask);
    end
    frame(positionY +ry, positionX + rx, :) = im2uint8(fondo);
end