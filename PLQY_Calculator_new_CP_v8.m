%% PLQY_Calculator_new_CP.m
% This code was originally written by Oleksandr Matiash, PhD.
% Received on 2025.05.04.
% 
% The code is used to calculate PLQY statistics from data collected from
% Olek's home-built VIS PLQY system.
%
% CP modified code to make it slightly more automated.
%
% v2, 2025.07.06, adapted for Avantis (new VIS) and NIR detectors.
% v3, 2025.07.08, added easy switch between VIS and NIR detectors.
% v4, 2025.07.09, generalized the code for having sample excitation and
% sample emission as potentially separate measurements.
% v5b, 2025.07.17, added residual excitation for comparison/subtraction;
% automated selection of files; added options for selecting whether there
% is a separate file for sample excitation or not and whether the center
% wavelength is the same or different for Ex vs Em.
% v7o, 2025.10.03, modified by Olek; added export of excitation and
% emission spectra for Origin

%--------------------Initialization-------------------------------
detector = 1;                   % 1 = Avantes (VIS); 2 = NIR
Percent_T_sphere=0.06365; %Transmittance of the ND filter used in the empty sphere experiment
Percent_T_sample=0.06365; %Transmittance of the ND filter used in the sample excitation experiment
Transm_sphere=Percent_T_sphere/100;
Transm_sample=Percent_T_sample/100;
%OD1=-log10(10.42/100);
OD_sphere=-log10(Transm_sphere); % OD value used for empty sphere measurement
OD_sample=-log10(Transm_sample);  % OD value used for sample excitation measurement                 
have_sample_excitation = 1;     % 0, sample excitation signal is contained in emission; 1, have separate file
have_residual = 0;              % 1, have residual data; 0, do not have residual data
same_range = 1;                 % 0, different center wavelength for Ex and Em; 1, same center wavelength


%------------------Define directory of measurements & files ----------------
group_dir = 'QFLS_loss_series_Drajad_25_10_25\wd\';

%---------------------Load correction file------------------------
if same_range == 0      % This is the section if there are different center wavelengths for Ex and Em.
    Correction_Ex=readtable('Intensity_calibration_routine\Correction_file_NIR_750nm_50acc_20250707.csv'); % calibration data
    Correction_Em=readtable('Intensity_calibration_routine\Correction_file_NIR_1000nm_50acc_20250707.csv'); % calibration data
    Correction_Ex=table2array(Correction_Ex);
    Correction_Em=table2array(Correction_Em);
    % Excitation data is stored in the first column. 
    % Emission data is stored in the second column.
    lambda = Correction_Ex(:,1); lambda(:,2) = Correction_Em(:,1);
    Correction_photons = Correction_Ex(:,2); Correction_photons(:,2) = Correction_Em(:,2);
else                    % This is the section if the Ex and Em center wavelengths are the same.
    if detector == 1
        Correction=readtable('Intensity_calibration_routine\Correction_file_VIS_270nm_50acc_20251023.csv'); % calibration data
    else
        readtable('Intensity_calibration_routine\Correction_file_NIR_750nm_50acc_20250707.csv'); % calibration data
    end
    Correction=table2array(Correction);
    lambda = repmat(Correction(:,1),1,2);
    Correction_photons = repmat(Correction(:,2),1,2);
end

%---------------------Define wavelength ranges-----------------------
laser = 512;            % [nm], laser central wavelength
laser_x1 = laser-10; % [nm], left integration boundary for the excitation peak
laser_x2 = laser+10; % [nm], right integration boundary for the excitation peak
emission_x1 = 700; % [nm], left integration boundary for the emission peak
emission_x2 = 900; % [nm], right integration boundary for the emission peak
residual_x1 = 460; % [nm], left integration boundary for the residual excitation signal
residual_x2 = 470; % [nm], right integration boundary for the residual excitation signal

% ---------------NO NEED TO EDIT BEYOND THIS POINT (MOSTLY)----------------
%--------------------------------------------------------------------------

% Find the file associated with the sample emission.
searchPattern = fullfile(group_dir, '*emission*');
emission_name = dir(searchPattern).name;

% Find the files associated with the empty sphere and sample excitation.
searchPattern = fullfile(group_dir, '*excitation*');
excitation_names = {dir(searchPattern).name};
sphere_Idx = contains(excitation_names, {'sphere','cuvette'});
empty_name = excitation_names{sphere_Idx};
if have_sample_excitation == 1
    sample_excitation_name = excitation_names{~sphere_Idx};
else
    sample_excitation_name = emission_name;
end

% Find the file assocaited with the residuals.
if have_residual == 1
    searchPattern = fullfile(group_dir, '*residual*');
    residual_name = dir(searchPattern).name;
end

%----------------------EMPTY SPHERE----------------------------------
if detector == 1    % VIS detector
    Empty = readmatrix([group_dir,empty_name]);
    rng = 2:size(Correction,1)+1;
    Empty_sphere_counts = Empty(rng,5)+84;
else                % NIR detector
    rng = 24:534; % NIR pixel range containing good data (do not change).
    Empty = readtable([group_dir,empty_name]);
    Empty = table2array(Empty);
    Empty_sphere_counts = Empty(rng,2);
end

%----------------------SAMPLE EMISSION--------------------------------
if detector == 1    % VIS detector
    Emission= readmatrix([group_dir,emission_name]);
    Emission_counts = Emission(rng,4);
    Background_emission_counts=Emission(rng,2);
    Emission_counts = Emission_counts-Background_emission_counts;
else                % NIR detector
    Emission= readtable([group_dir,emission_name]);
    Emission = table2array(Emission);
    Emission_counts = Emission(rng,2);
end

%----------------------SAMPLE EXCITATION--------------------------------
if detector == 1    % VIS detector
    Excitation = readmatrix([group_dir,sample_excitation_name]);
    Excitation_counts = Excitation(rng,5)+84;
    Background_excitation_counts=Excitation(rng,2);
    %Excitation_counts=Excitation_counts-Background_excitation_counts;
else                % NIR detector
    Excitation = readtable([group_dir,sample_excitation_name]);
    Excitation = table2array(Excitation);
    Excitation_counts = Excitation(rng,2);
end

%----------------------RESIDUAL EXCITATION--------------------------------
if have_residual == 1
    if detector == 1    % VIS detector
        Residual = readmatrix([group_dir,residual_name]);
        Residual_counts = Residual(rng,5);
    else                % NIR detector
        Residual = readtable([group_dir,residual_name]);
        Residual = table2array(Residual);
        Residual_counts = Residual(rng,2);
    end
end

%----------------Find wavelength range for integration----------------
[~,laser_xi1] = min(abs(lambda(:,1)-laser_x1));
[~,laser_xi2] = min(abs(lambda(:,1)-laser_x2));
[~,emission_xi1] = min(abs(lambda(:,2)-emission_x1));
[~,emission_xi2] = min(abs(lambda(:,2)-emission_x2));
[~,residual_xi1] = min(abs(lambda(:,2)-residual_x1));
[~,residual_xi2] = min(abs(lambda(:,2)-residual_x2));

%--------------------Correction--------------------------------------
Empty_counts_corrected = Empty_sphere_counts.*Correction_photons(:,1);
Emission_counts_corrected = Emission_counts.*Correction_photons(:,2);
Excitation_counts_corrected = Excitation_counts.*Correction_photons(:,1);
if have_residual == 1
    Residual_counts_corrected = Residual_counts.*Correction_photons(:,2);
end

%--------------------Remove residual excitation-------------------------
% Calculate the scaled residuals and subtract from the sample emission.
if have_residual == 1
    sample_residual_SF = trapz(lambda(residual_xi1:residual_xi2,2),Emission_counts_corrected(residual_xi1:residual_xi2));
    empty_residual_SF =  trapz(lambda(residual_xi1:residual_xi2,2),Residual_counts_corrected(residual_xi1:residual_xi2));
    Residual_counts_corrected = Residual_counts_corrected.*sample_residual_SF./empty_residual_SF;
    No_corr=Emission_counts_corrected;
    Emission_counts_corrected = Emission_counts_corrected - Residual_counts_corrected;
end

%--------------------Calculate Attenuation factors------------------------
AF_sphere = 10^OD_sphere;     % attenuation factor of the empty sphere
AF_sample = 10^OD_sample;     % attenuation factor of the sample excitation

%---------------Plot spectral regions of interest-------------------
% Exitation range
figure(1);
plot(lambda(:,1),Empty_counts_corrected.*AF_sphere,'linewidth',2);
hold on; 
plot(lambda(:,1),Excitation_counts_corrected.*AF_sample,'linewidth',2);
hold off;
xlabel('Wavelength, nm'); ylabel('Number of photons/nm');
legend ('Empty sphere (Ex)','Sample (Ex)');
xlim([laser_x1-5, laser_x2+5]);

% Emission range
figure(2);
plot(lambda(:,1),Empty_counts_corrected,'linewidth',2);
hold on; 
plot(lambda(:,2),Emission_counts_corrected,'linewidth',2);

if have_residual == 1
    plot(lambda(:,2),No_corr,'linewidth',2);
    plot(lambda(:,2),Residual_counts_corrected,'linewidth',2);
    legend ('Empty sphere (Em)','Sample (Em)','No correction', 'Residual');
else
    legend ('Empty sphere (Em)','Sample (Em)','No correction');
end
hold off;
xlabel('Wavelength, nm'); ylabel('Number of photons/nm');
xlim([emission_x1-50, emission_x2+50]);
xlim([450 1000]);
yscale = max(Emission_counts_corrected((lambda(:,2)>emission_x1)&(lambda(:,2)<emission_x2)));
ylim([-yscale*0.1 yscale*1.1]);

%--------------------Integration--------------------------------------
Area_empty = trapz(lambda(laser_xi1:laser_xi2,1),Empty_counts_corrected(laser_xi1:laser_xi2));
Area_excitation = trapz(lambda(laser_xi1:laser_xi2,1),Excitation_counts_corrected(laser_xi1:laser_xi2));
Area_emission = trapz(lambda(emission_xi1:emission_xi2,2),Emission_counts_corrected(emission_xi1:emission_xi2));
Area_empty = Area_empty*AF_sphere;
Area_excitation = Area_excitation*AF_sample;
PLQY = (Area_emission/(Area_empty-Area_excitation))*100;

fprintf('PLQY = %0.3f%% \n',PLQY);
% fprintf('Absorption = %0.1f%% \n',(1-Area_excitation/Area_empty)*100);

%-------------Output data for Origin plots-----------------------------
Mout_absolute_PL = [lambda(:,2), mean(Emission_counts_corrected,2)];
Mout_PLQY = PLQY';
if have_residual==0
    columns=["Wavelength ex","Wavelength em","Empty sphere excitation","Residual excitation","Emission"];
%Data=[columns;lambda(:,2),Empty_counts_corrected,Excitation_counts_corrected,Emission_counts_corrected];
writematrix ([lambda(:,1),Empty_counts_corrected,Excitation_counts_corrected,lambda(:,2),Emission_counts_corrected],group_dir+"PLQY_data.csv")
else
    columns=["Wavelength","Empty sphere excitation","Residual excitation","Excitation tail","Emission"];
    Data=[columns;lambda(:,2),Empty_counts_corrected,Excitation_counts_corrected,Residual_counts_corrected,Emission_counts_corrected];
    writematrix ([lambda(86:1217,2),Empty_counts_corrected(86:1217,:),Excitation_counts_corrected(86:1217,:),Residual_counts_corrected(86:1217,:),Emission_counts_corrected(86:1217,:)],group_dir+"PLQY_data.csv")
end

% Eph=4.85e-19; %photon energy for 408 nm, J
% t_int=1; %integration time, s
% A_power=1000*Area_empty*Eph/t_int

