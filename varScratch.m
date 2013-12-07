% function [ Xpred, Xactual, avgPctErr, Pi] = varScratch(Xraw)
%VARSCRATCH Scratch testing function for our VAR model


% if nargin < 1
%     %Training data specifications
%     % year = 2010;
%     % days = 258:268;
%     % hours= 0:23;
%     % % varNames = {'N2-m_above_ground_Temperature', 'Pressure', 'N10-m_above_ground_Meridional_wind_speed', 'N2-m_above_ground_Specific_humidity'};
%     % varNames = {'Pressure'};
%     % latRange = [40,41];
%     % lonRange = [-80, -79];
%     year = 2010;
%     days = 259:288;
%     hours= 0:23;
%     varNames = {'Precipitation_hourly_total', ...
%                 'N180-0_mb_above_ground_Convective_Available_Potential_Energy', ...
%                 'Fraction_of_total_precipitation_that_is_convective', ...
%                 'LW_radiation_flux_downwards_surface', ...
%                 'SW_radiation_flux_downwards_surface', ...
%                 'Potential_evaporation', ...
%                 'Pressure', ...
%                 'N2-m_above_ground_Specific_humidity', ...
%                 'N2-m_above_ground_Temperature', ...
%                 'N10-m_above_ground_Zonal_wind_speed', ...
%                 'N10-m_above_ground_Meridional_wind_speed' ...
%                 };
%     % latRange = [40.062999725341800,40.062999725341800];
%     % lonRange = [-80.063003540039060,-80.063003540039060];
%     latRange = [40.1875, 40.9];
%     lonRange = [-80.3125, -79.5];
% %     latRange = [40.062999725341800,40.062999725341800];
% %     lonRange = [-80.063003540039060,-80.063003540039060];

    % 
    %Downloading data (only run when needed!)
    % for day = days
    %    downloadDataForDay(year, day);
    % end

    %LOADING FROM DISK: Note that commenting this out once Xraw is loaded is a useful debugging speed boost.
%     Xraw = loadData(varNames, latRange, lonRange, year, days, hours);

    %Or, load a previously saved version
    singleCellModel = false;
    if singleCellModel
        load 'Xraw.mat';  %Single-cell data
        blockSize = 1; %assumed # of cells in data (NOTE THE HARDCODING)
    else
        load 'XrawFull.mat';    %All-cell data
        blockSize = 36; %assumed # of cells in data (NOTE THE HARDCODING) 
    end

    % %DEBUGGING: Load same data set as used for linear regression
    % %NOTE: ONLY WILL WORK FOR LOOKING AT SINGLE CELL. Need to modify layout of
    % %data to match how we load GRB data otherwise
    % load './src/linReg/dinLinReg.txt';
    % numTimesteps = 720;
    % Xraw = dinLinReg;
    % totVars = size(Xraw, 2) / 2;
    % %Cut out so we're looking at data for just one cell
    % Xraw = Xraw(1:numTimesteps, 1:totVars);
    % %TEST: Only look at one variable
    % Xraw = Xraw(:,9);

    % % DEBUGGING ONLY: Generate random time series data w/ noise
    % debugT = 100;
    % debugN = 1;
    % debugNoiseStdDev = 0.1;
    % clear Xraw;
    % Xraw(1,:) = ones(1, debugN);
    % for i=2:debugT
    %    Xraw(i,:) = 0.8 * Xraw(i-1,:);%debugNoiseStdDev*randn(1,debugN);
    % end

    % %DEBUGGING ONLY: Sine-wave signal
    % debugT = 100;
    % debugNoiseStdDev = 0.001;
    % clear Xraw;
    % for i=1:debugT
    %    Xraw(i,1) = sin((i-1)/20) + debugNoiseStdDev*randn(1,1);
    %    Xraw(i,2) = cos((i-1)/20) + debugNoiseStdDev*randn(1,1);
    %    Xraw(i,3) = sin((i-1)/10) + debugNoiseStdDev*randn(1,1);
    %    Xraw(i,4) = sin((i-1)/1) + debugNoiseStdDev*randn(1,1);
    % end
% end

X = Xraw;

%Data whitening
%Source: http://metaoptimize.com/qa/questions/4985/what-exactly-is-whitening
M = mean(Xraw);
X = bsxfun(@minus, X, M); %shift to 0-mean
%Method #1
% C = cov(X);
% [V,D] = eig(C);
% P = V * diag(sqrt(1./(diag(D) + 0.1))) * V';
% X = X * P;
%Method #2
% [T, N] = size(X);
% W = sqrt(N) * sqrt(X*X');
% X = W * X;
%Method #3: Not really whitening... just use unit variance for each var
%Using this since real whitening (using prior methods) was giving
%complex-valued data.... :(
stdXRaw = std(Xraw);
X = bsxfun(@rdivide, X, stdXRaw);

%Diffs (for removing trends)
% X = diff(X,1);

%DEBUGGING ONLY
% X = X(1:20,:);

%Splice out any variables which we don't wish to include in the model
varsOfInterest = 7:9;

%Lag of the model (ie: how many prior timesteps to include in the model)
%This should be less than the # of timesteps in training data, or sadness
%will result.
ps = 1:2;

trainPct = 0.2;

%Single-var-at-a-time version
% i = 1;
% for varOfInterest = varsOfInterest
%     XsingleVar =  X(:,1+blockSize*(varOfInterest-1):blockSize*varOfInterest);
%     avgPctErr(i) = doVAR(XsingleVar, ps, trainPct);
%     i = i+1;
% end
% avgPctErrAcrossVarsAndLags = mean2(avgPctErr)
% stdPctErrAcrossVarsAndLags = std2(avgPctErr)

%Fig 3 & 4 of poster: RMS error with and without neighbor cells in model or other variables in model
%Multi-vars version
Xspliced = zeros(size(X,1), blockSize * length(varsOfInterest));
i = 1;
for varOfInterest = varsOfInterest
    Xspliced(:,1+blockSize*(i-1):blockSize*i) = X(:,1+blockSize*(varOfInterest-1):blockSize*varOfInterest);
    i = i + 1;
end
X = Xspliced;

[avgPctErr, Pi] = doVAR(X, ps, trainPct);
avgPctErrAcrossVarsAndLags = mean2(avgPctErr)
stdPctErrAcrossVarsAndLags = std2(avgPctErr)

%Fig 5 of poster: Test error vs. lag order
avgPctErrAcrossVars = mean(avgPctErr,2);
xMin = ps(1); xMax = ps(end); yMin = 0; yMax = 1;
plot(avgPctErrAcrossVars, 'LineWidth', 5, 'Color', [0.3,0.3,1]);
% firstQuartileErrs       = prctile(avgPctErr, 25, 2);
% thirdQuartileErrs       = prctile(avgPctErr, 75, 2);
% %Returned handles: struct w/ mainLine, patch, and edge[2]
% plotH = shadedErrorBar(ps, avgPctErrAcrossVars', [thirdQuartileErrs'; firstQuartileErrs'], '-r', 0);
% set(plotH.mainLine, 'LineWidth', 4);
% title(sprintf('Training Error'));
title(sprintf('Training Error'));
xlabel('Lag Order');
ylabel(sprintf('Error'));
axis([xMin xMax yMin yMax]);
set(gca, 'XTick', 0:1:xMax);
% set(gca, 'YTick', [yMin::yMax]);
%Switch to % on y-axis (SOURCE: http://www.mathworks.com/matlabcentral/answers/94708)
% Convert y-axis values to percentage values by multiplication
a=[cellstr(num2str(get(gca,'ytick')'*100))]; 
% Create a vector of '%' signs
pct = char(ones(size(a,1),1)*'%'); 
% Append the '%' signs after the percentage values
new_yticks = [char(a),pct];
% 'Reflect the changes on the plot
set(gca,'yticklabel',new_yticks) 
box off;
sdf('10_701'); %apply our style (make sure it exists on your machine!)


% end

