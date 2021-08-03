function sRunSpeed = PP_GetRunSpeed(vecData,sMetaNI)
	%PP_GetRunSpeed Transforms encoder pulses to run speed. Syntax:
	%   sRunSpeed = PP_GetRunSpeed(vecData,sMetaNI)
	%
	%	input:
	%	- matImage; [X by Y] image matrix (can be gpuArray)
	%	- matFilt: [M by N] filter matrix (can be gpuArray)
	%	- strPadVal: optional (default: 'symmetric'), padding type using padarray.m
	%
	%	output: structure with the following fields:
	%	- vecOutT; vector with timestamps (t0=0) (in seconds)
	%	- vecTraversed_m: traversed distance per time step (in meters)
	%	- vecSpeed_mps: filtered running speed over last 1s (in m/s)
	%
	%Version history:
	%1.0 - 3 August 2021
	%	Created by Jorrit Montijn
	
	%% define constants
	dblStepV = 2220; %int16 values between voltage steps
	dblStaticV = -5583; %int16 value of voltage at rest when wheel is still
	dblWheelCircumference = 0.534055; %meter; circumference of running wheel
	dblPulsesPerCircumference = 1024; %pulse # over 2pi for one full rotation
	dblSampRatePulses = 1000; %sampling frequency of encoder updates
	
	%% extract discrete voltage levels
	dblSampRateNi = str2double(sMetaNI.niSampRate);
	vecT = (1:numel(vecData))/dblSampRateNi;
	vecRunStep=round((-vecData+dblStaticV)/dblStepV);
	
	%% get 1ms-step output
	dblReduceBy = dblSampRateNi/dblSampRatePulses;
	vecOutT = (1/dblSampRatePulses):(1/dblSampRatePulses):vecT(end);
	vecFilt = ones([1 round(dblReduceBy)])/dblReduceBy;
	try
		%try gpu filtering
		vecRunStep = gpuArray(vecRunStep);
		vecFilt = gpuArray(vecFilt);
	catch
	end
	vecMean = imfilt(vecRunStep,vecFilt);
	indKeepVals = diff(mod(vecT-0.5/dblSampRatePulses,1/dblSampRatePulses))<0;
	vecOutV = vecMean(indKeepVals);

	%% transform to distance+speed
	dblMeterPerPulse = dblWheelCircumference/dblPulsesPerCircumference;
	vecTraversed_m = vecOutV*dblMeterPerPulse; %distance in meter: pulse * (meter/pulse) = meter/ms
	vecTraversed_m = vecTraversed_m((numel(vecTraversed_m) - numel(vecOutT) + 1):end);
	vecFiltSecondSum = ones([1 round(dblSampRatePulses)]);
	vecSpeed_mps = imfilt(vecTraversed_m,vecFiltSecondSum); %sum over 1 second: meter per second
	vecSpeed_mps = vecSpeed_mps((numel(vecSpeed_mps) - numel(vecTraversed_m) + 1):end);
	
	%build output
	sRunSpeed = struct;
	sRunSpeed.vecOutT = vecOutT;
	sRunSpeed.vecTraversed_m = gather(vecTraversed_m);
	sRunSpeed.vecSpeed_mps = gather(vecSpeed_mps);
end