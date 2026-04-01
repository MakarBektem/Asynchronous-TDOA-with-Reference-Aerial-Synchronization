clear all
close all

%% АЛГОРИТМ БЕЗ ИНТЕРПОЛЯЦИИ c cинхрой по одному самолету

c = 299792458; % скорость света в м/с
wgs84 = wgs84Ellipsoid('meter');

% координаты 0 точки
lat0 = 59.98323611;  % широта
lon0 = 30.32988277;  % долгота
h0 = 38; % высота в метрах
[x0, y0, z0] = geodetic2ecef(wgs84, lat0, lon0, h0);
A0 = [x0 y0 z0];

% координаты 1 точки
lat1 = 60.41250978;
lon1 = 30.47153636;
h1 = 102; % высота в метрах
[x1, y1, z1] = geodetic2ecef(wgs84, lat1, lon1, h1);
A1 = [x1 y1 z1];

% координаты 2 точки
lat2 = 59.97149735;
lon2 = 29.37903999;
h2 = 35; % высота в метрах
[x2, y2, z2] = geodetic2ecef(wgs84, lat2, lon2, h2);
A2 = [x2 y2 z2];

% координаты 3 точки
lat3 = 60.02640400;
lon3 = 29.84501100;
h3 = 25; % высота в метрах
[x3, y3, z3] = geodetic2ecef(wgs84, lat3, lon3, h3);
A3 = [x3 y3 z3];

% координаты 4 точки (виртуальной)
lat4 = 60.40619206;
lon4 = 29.46862628;
h4 = 35; % высота в метрах
[x4, y4, z4] = geodetic2ecef(wgs84, lat3, lon3, h3);
A4 = [x4 y4 z4];

% считываем данные с позиций
SPB = readtable('22_01_19_12_00_00__0__spb__59.98316100__30.32986400__20.dat'); 
OBK = readtable('22_01_19_12_00_00__1__obk__60.41248200__30.47153100__20.dat');
DMT = readtable('22_01_19_12_00_00__2__dmt__59.97149000__29.37904000__20.dat');
DMB = readtable('22_01_19_12_00_00__3__dmb__60.02640400__29.84501100__20.dat');

a = find(SPB.Var1 == duration('12:20:00')); % ищем индекс строки в СПб, которая соответствует 10 минуте с начала записи
a = find(SPB.Var1 == duration('12:20:00')); % ищем индекс строки в СПб, которая соответствует 10 минуте с начала записи

%% Синхронизация 

hex_code1 = '155C56';   % код самолета для местоопределения

idx0 = zeros(1, size(SPB,1));
idx1 = zeros(1, size(SPB,1));
idx2 = zeros(1, size(SPB,1));
idx3 = zeros(1, size(SPB,1));

TDOA10 = zeros(1, size(SPB,1));
TDOA20 = zeros(1, size(SPB,1));
TDOA30 = zeros(1, size(SPB,1));

    for i=1:a(end)
    
        strSPB = SPB(i, :);     % текущая строка СПб
        strSPB_hex = char(strSPB.Var3);  % код самолета из текущей строки
            
        if ~strcmp(strSPB_hex, hex_code1) && ~isnan(strSPB.Var7) % если в строке совпадает название самолета и есть координаты (столбец 7 не пуст)
    
            packSPB = char(strSPB.Var5);   % записываем пакет для поиска в других позициях
            num1 = find(strcmp(OBK.Var5, packSPB));    % Индекс строки в ОБП, содержащей пакет из строки СПБ
            num2 = find(strcmp(DMT.Var5, packSPB));    % Индекс строки в ДМТ, содержащей пакет из строки СПБ
            num3 = find(strcmp(DMB.Var5, packSPB));    % Индекс строки в ДМБ, содержащей пакет из строки СПБ
            
            if ~isempty(num1) && ~isempty(num2) && ~isempty(num3)     % если текущая строка из СПБ есть в ОБП и ДМТ
                
                strOBK = OBK(num1, :);     % текущая строка
                strDMT = DMT(num2, :);
                strDMB = DMB(num2, :);
               
                idx0(i) = strSPB.Var2;  % достаем значения счетчиков
                idx1(i) = strOBK.Var2;
                idx2(i) = strDMT.Var2;
                idx3(i) = strDMB.Var2;
                
                lat_op = strSPB.Var7;   % достаем координаты самолета из пакета
                lon_op = strSPB.Var8;
                h_op = strSPB.Var6;
                [x_op, y_op, z_op] = geodetic2ecef(wgs84, lat_op, lon_op, h_op);

                A_op = [x_op y_op z_op];

                TOA0 = norm(A_op - A0) / c;    % время В СЕКУНДАХ, за которое пакеты дошли от самолета до позиций
                TOA1 = norm(A_op - A1) / c;
                TOA2 = norm(A_op - A2) / c;
                TOA3 = norm(A_op - A3) / c;
    
                TDOA10(i) = TOA1 - TOA0;
                TDOA20(i) = TOA2 - TOA0;
                TDOA30(i) = TOA3 - TOA0;
            end
        end
    end

idx0 = nonzeros(idx0);
idx1 = nonzeros(idx1);
idx2 = nonzeros(idx2);
idx3 = nonzeros(idx3);

TDOA10 = nonzeros(TDOA10);
TDOA20 = nonzeros(TDOA20);
TDOA30 = nonzeros(TDOA30);

% figure('Name', 'Графики синхры', 'NumberTitle', 'off');
% subplot(4, 1, 1)
% plot(idx0, zeros(1, length(idx0)), '.')
% legendtext = sprintf('%s Моменты синхронизации СПб %.2f', 1);
% legend(legendtext);
% grid on;
% hold on;
% 
% subplot(4, 1, 2)
% plot(idx1, zeros(1, length(idx1)), '.')
% legendtext = sprintf('%s Моменты синхронизации ОБК %.2f', 1);
% legend(legendtext);
% grid on;
% hold on;
% 
% subplot(4, 1, 3)
% plot(idx2, zeros(1, length(idx2)), '.')
% legendtext = sprintf('%s Моменты синхронизации ДМТ %.2f', 1);
% legend(legendtext);  
% grid on;
% hold on;
% 
% subplot(4, 1, 4)
% plot(idx2, zeros(1, length(idx2)), '.')
% legendtext = sprintf('%s Моменты синхронизации ДМТ %.2f', 1);
% legend(legendtext);  
% grid on;
% hold on;

%% Местоопределение                 
lat = zeros(1, size(SPB,1));
lon = zeros(1, size(SPB,1));

lat_ = zeros(1, size(SPB,1));
lon_ = zeros(1, size(SPB,1));
h_ = zeros(1, size(SPB,1));

for i = 1:a(end)
    strSPB = SPB(i, :);     % текущая строка
    strSPB_hex = strSPB.Var3;  % код самолета из текущей строки
    strSPB_hex = char(strSPB_hex);

    if strcmp(strSPB_hex, hex_code1) && ~isnan(strSPB.Var7)  % если в строке совпадает название самолета и есть координаты (столбец 7 не пуст)
    
        packSPB = char(strSPB.Var5);   % записываем пакет для поиска в других позициях
        num1 = find(strcmp(OBK.Var5, packSPB));    % строка в ОБП, содержащая пакет из строки СПБ
        num2 = find(strcmp(DMT.Var5, packSPB));  
        num3 = find(strcmp(DMB.Var5, packSPB));    
    
        if ~isempty(num1) && ~isempty(num2) && ~isempty(num3)      % если текущая строка из СПБ есть везде
    
            strOBK = OBK(num1, :);     % текущая строка ОБК
            strDMT = DMT(num2, :);     % текущая строка ДМТ
            strDMB = DMB(num2, :);     % текущая строка ДМБ

            lat(i) = strSPB.Var7;   % достаем координаты самолета из строки
            lon(i) = strSPB.Var8;
            h = strSPB.Var6;

            [x_, y_, z_] = geodetic2ecef(wgs84, lat(i), lon(i), h);
            A_ = [x_ y_ z_];

            TOA0 = norm(A_ - A0) / c;    % время В СЕКУНДАХ, за которое пакеты дошли от самолета до позиций
            TOA3 = norm(A_ - A3) / c;
            TDOA30 = TOA3 - TOA0;

            TOA4 = norm(A_ - A4) / c;
            TDOA40 = TOA4 - TOA0;
         
            idx0_N = strSPB.Var2;  % текущее значениe счетчика в СПб
            idx1_N = strOBK.Var2;  % значениe счетчика в ОБК
            idx2_N = strDMT.Var2;  % значениe счетчика в ДМТ
            idx3_N = strDMB.Var2;  % значениe счетчика в ДМБ
                      
            mask = idx0 <= idx0_N;     % Находим логический индекс всех значений <= текущего счетчика
            valid_values = idx0(mask);
            [~, num_sync] = max(valid_values);        % индекс в отфильтрованном массиве

            TOA0 = idx0_N - idx0(num_sync);
            TOA1 = idx1_N - idx1(num_sync) + TDOA10(num_sync) * 1.e9;
            TOA2 = idx2_N - idx2(num_sync) + TDOA20(num_sync) * 1.e9;
%             TOA3 = idx3_N - idx3(num_sync) + TDOA30(num_sync) * 1.e9;
            
            TDOA10_ = (TOA1 - TOA0) / 1.e9;
            TDOA20_ = (TOA2 - TOA0) / 1.e9;
%             TDOA30_ = (TOA3 - TOA0) / 1.e9;
            
            syms x y z
            
            f1 = sqrt((x - x1)^2 + (y - y1)^2 + (z - z1)^2) - sqrt((x - x0)^2 + (y - y0)^2 + (z - z0)^2) == c * TDOA10_; 
            f2 = sqrt((x - x2)^2 + (y - y2)^2 + (z - z2)^2) - sqrt((x - x0)^2 + (y - y0)^2 + (z - z0)^2) == c * TDOA20_;
            f3 = sqrt((x - x3)^2 + (y - y3)^2 + (z - z3)^2) - sqrt((x - x0)^2 + (y - y0)^2 + (z - z0)^2) == c * TDOA30;
            f4 = sqrt((x - x4)^2 + (y - y4)^2 + (z - z4)^2) - sqrt((x - x0)^2 + (y - y0)^2 + (z - z0)^2) == c * TDOA40;
                   
            eqns = [f1, f2, f3, f4];
            vars = [x y z];
            
            Sa = solve(eqns, vars);
            
            [lat_(i), lon_(i), h_(i)] = ecef2geodetic(wgs84, double(vpa(Sa.x(1), 7)), double(vpa(Sa.y(1), 7)), double(vpa(Sa.z(1), 7)));
        end
     end
end

lat = nonzeros(lat);
lon = nonzeros(lon);

lat_ = nonzeros(lat_);
lon_ = nonzeros(lon_);

figure
geoplot(lat, lon, '-o');    % c простым plot НАОБОРОТ: сначала lon потом lat
geobasemap ('topographic'); 
hold on
geoplot(lat_, lon_, '-o');
geoplot(lat0, lon0, 'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
geoplot(lat1, lon1, 'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
geoplot(lat2, lon2, 'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
geoplot(lat3, lon3, 'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
hold off

