function frame = maskBanner(frame, banner, banner_mask, positionX, positionY)

    % Convierte banner y máscara a double si no lo están
    banner = im2double(banner);
    banner_mask = im2double(banner_mask);
    
    % Calcula los rangos de píxeles
    rx = [1:size(banner, 2)] - 1; 
    ry = [1:size(banner, 1)] - 1;
    
    % Verifica que el banner cabe en el frame
    if positionY + ry(end) > size(frame, 1) || positionX + rx(end) > size(frame, 2)
        warning('El banner se sale del frame. No se aplicará.');
        return;
    end
    
    % Extrae la región del fondo
    fondo = im2double(frame(positionY + ry, positionX + rx, :));
    
    % Fusión con alpha blending para cada canal de color
    for c = 1:3
        fondo(:,:,c) = banner(:,:,c) .* banner_mask + fondo(:,:,c) .* (1 - banner_mask);
    end
    
    % Inserta la región fusionada de vuelta en el frame
    frame(positionY + ry, positionX + rx, :) = im2uint8(fondo);
end