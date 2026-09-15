clear all
close all
clc
n=101; %number of columns to read

%------------------Lamp Calibration Data Loading-------------------------%
folder="C:\Users\PLQY_user\Desktop\Users\Chris\Scripts\Intensity_calibration_routine";
file="Lamp_calibration_data_DONOTCHANGE";
LAMP_Calib=readtable(folder+"\"+file+".csv");
LAMP_Calib=table2array(LAMP_Calib);
Wavelength_cal_file=LAMP_Calib(1:22,1); %Wavelength from the Intensity file, nm
Intensity_uW=LAMP_Calib(1:22,2); %Intensity file, uW/nm

%-------------Wavelength Calibration File Loading------------------------%
file="Calibration-table-cnt-1000nm";
Wavelength_calib=readtable(folder+"\"+file+".csv");
Wavelength_calib=table2array(Wavelength_calib);
Pixel=Wavelength_calib(:,1); %Pixel number, a. u.
Wavelength_setup=Wavelength_calib(:,2); %Wavelength calibration, nm


%--------------Measured Lamp Data Loading----------------------------%
folder="C:\Users\MATIO0A\Desktop\PhD\PLQY\New_setup_calibration\20250529 - calibration";
file="29_05_25_16_31_50_360E+0_ms_Ocean Insight HL3-ext lamp center lam 700 nm - background";%Background
Background=readtable(folder+"\"+file+".csv");
Background=table2array(Background);

file="29_05_25_16_22_03_360E+0_ms_Ocean Insight HL3-ext lamp center lam 700 nm";%Background
Lamp_Data=readtable(folder+"\"+file+".csv");
Lamp_Data=table2array(Lamp_Data);

Intensity_counts=mean(Lamp_Data(:,2:n),2); %Lamp signal in counts
Background_counts=mean(Background(:,2:n),2); %Background signal in counts
Intensity_bg_subtracted=Intensity_counts-Background_counts;

Intensity_W=Intensity_uW/1e6; %Intensity file in W/nm

figure(1)
plot(Wavelength_cal_file,Intensity_W,'o')
xlabel('Wavelength, nm')
ylabel('Intensity, W/nm')
grid on

Intensity_W_interp=interp1(Wavelength_cal_file,Intensity_W,Wavelength_setup);

figure(2)
plot(Wavelength_cal_file,Intensity_W,'o', Wavelength_setup, Intensity_W_interp,'^')
xlabel('Wavelength, nm')
ylabel('Intensity, W/nm')
legend('File','Interpolated')
grid on

Correction_W=Intensity_W_interp./Intensity_counts; %Correction file in W/(nm*counts)=J/(s*nm*count);

figure(3)
plot(Wavelength_setup,Correction_W)
xlabel('Wavelength, nm')
ylabel('Correction, W/(nm*count)')
grid on
t_int=360e-3; %integration time, s
Correction_J=Correction_W*t_int; %Correction file in J/(nm*count)
figure(4)
plot(Wavelength_setup,Correction_J)
xlabel('Wavelength, nm')
ylabel('Correction, J/(nm*count)')
grid on


h=6.6261e-34; %Planck's constant in J*s
c=299792458; %speed of light in m/s
E_photon_J=h*c*1e9./Wavelength_setup; %photon energy axis in J: J*s*nm/(s*nm)=J
E_photon_eV=1240./Wavelength_setup;%photon energy axis in eV
Correction_photons=Correction_J./E_photon_J; %Correction file in photons/(nm*count)
figure(5)
plot(Wavelength_setup, Correction_photons)
xlabel('Wavelength, nm')
ylabel('Correction, photons/(nm*count)')
grid on
Correction_full=[Wavelength_setup, Correction_photons];
% %writematrix(Correction_full,'Correction_file_10_11_24.csv');
%------------------TEST-------------------------------
Test=readtable('Test.csv'); %Test data
Test=table2array(Test);
Test_mean=mean(Test,2)
Test_difference=Test_mean-Data(:,5);
%Test_difference=900*exp((-((Wavelength_setup-800)).^2)/2*(0.1^2));
figure(6)
plot(Wavelength_setup,Test_difference);
grid on
Reconstructed=Correction_W.*Test_difference;
figure(7)
%plot(Wavelength_setup,Reconstructed);
plot(Wavelength_setup,Intensity_W_interp,Wavelength_setup,Reconstructed)
xlabel('Wavelength, nm')
ylabel('Intensity, W/nm')
grid on
Difference_abs=(abs(Reconstructed-Intensity_W_interp));
Difference_rel=(abs(Reconstructed-Intensity_W_interp)./Intensity_W_interp)*100;
figure(8)
subplot(2,1,1)
plot(Wavelength_setup,Difference_abs)
xlabel('Wavelength, nm')
ylabel('Absolute error, W/nm')
grid on
subplot(2,1,2)
plot(Wavelength_setup,Difference_rel)
xlabel('Wavelength, nm')
ylabel('Relative error, %')
grid on