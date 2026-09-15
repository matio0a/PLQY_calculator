% Changed on 2025.07.06 to account for NIR and Avantes spectrographs;
% neither require separate background files.
t_int=0.5;           % integration time, s
detector = 1;           % 1 = Avantes (VIS); 2 = NIR
center_lambda = 270;   % [nm], center wavelength
averages = 50;          % set number of averages
date = 20251023;        % date for file name

%------------------Lamp Calibration Data Loading-------------------------%
folder="C:\Users\PLQY_user\Desktop\Users\Chris\Scripts\Intensity_calibration_routine";
file="Lamp_calibration_data_DONOTCHANGE";
LAMP_Calib=readtable(folder+"\"+file+".csv");
LAMP_Calib=table2array(LAMP_Calib);
Wavelength_cal_file=LAMP_Calib(:,1); % Wavelength from the Intensity file, nm
Intensity_uW=LAMP_Calib(:,2); % Intensity file, uW/nm
Intensity_W=Intensity_uW/1e6; %Intensity file in W/nm

%--------------Measured Lamp Data Loading----------------------------%
folder="C:\Users\PLQY_user\Desktop\Data\Black_calibration_lamp_23_10_25";
file="lamp270_Intensity_calibration_int1s_aver50_date_23_10_25_2106509U1"; % Lamp (measured)

if detector == 1    % VIS detector
    Lamp_Data=readmatrix(folder+"\"+file+".txt");
    rng = 2:size(Lamp_Data,1);
    col = 5;    % column with background-subtracted data
else                % NIR detector
    Lamp_Data=readtable(folder+"\"+file+".csv");
    Lamp_Data=table2array(Lamp_Data);
    rng = 24:534;
    col = 2;    % column with background-subtracted data
end

Intensity_counts=Lamp_Data(rng,col); % Lamp signal in counts
Wavelength_setup=Lamp_Data(rng,1); % Wavelength in nm

%--------------Make Useful Plots----------------------------%
% Measured lamp spectrum
figure(1); plot(Wavelength_setup,Intensity_counts);
xlabel('Wavelength (nm)');
ylabel('Intensity (counts)');

% Intensity calibration file with interpolated points
Intensity_W_interp=interp1(Wavelength_cal_file,Intensity_W,Wavelength_setup);
figure(2);
plot(Wavelength_cal_file,Intensity_W,'o', Wavelength_setup, Intensity_W_interp,'^');
xlabel('Wavelength, nm');
ylabel('Intensity, W/nm');
legend('File','Interpolated');

% Calculate correction file in W/(nm*count) or J/(nm*count)
Correction_W=Intensity_W_interp./Intensity_counts; % Correction file in W/(nm*counts)=J/(s*nm*count);
Correction_J=Correction_W*t_int; %Correction file in J/(nm*count)

% Calculate correction file in photons/(nm*count)
h=6.6261e-34; % Planck's constant in J*s
c=299792458; % speed of light in m/s
E_photon_J=h*c*1e9./Wavelength_setup; % photon energy axis in J: J*s*nm/(s*nm)=J
E_photon_eV=1240./Wavelength_setup; % photon energy axis in eV
Correction_photons=Correction_J./E_photon_J; % Correction file in photons/(nm*count)

% Make plot of correction file
figure(3);
plot(Wavelength_setup, Correction_photons);
xlabel('Wavelength, nm');
ylabel('Correction, photons/(nm*count)');
Correction_full=[Wavelength_setup, Correction_photons];

% Save correction file
if detector == 1
    detnom = 'VIS';
else
    detnom = 'NIR';
end
writematrix(Correction_full,['Correction_file_',detnom,'_',num2str(center_lambda),'nm_',num2str(averages),'acc_',num2str(date),'.csv']);
