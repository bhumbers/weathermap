function [ Xpred, Xactual] = varScratch(Xraw)
%VARSCRATCH Scratch testing function for our VAR model


if nargin < 1
    %Training data specifications
    % year = 2010;
    % days = 258:268;
    % hours= 0:23;
    % % varNames = {'N2-m_above_ground_Temperature', 'Pressure', 'N10-m_above_ground_Meridional_wind_speed', 'N2-m_above_ground_Specific_humidity'};
    % varNames = {'Pressure'};
    % latRange = [40,41];
    % lonRange = [-80, -79];
    year = 2010;
    days = 259:288;
    hours= 0:23;
    varNames = {'Precipitation_hourly_total', ...
                'N180-0_mb_above_ground_Convective_Available_Potential_Energy', ...
                'Fraction_of_total_precipitation_that_is_convective', ...
                'LW_radiation_flux_downwards_surface', ...
                'SW_radiation_flux_downwards_surface', ...
                'Potential_evaporation', ...
                'Pressure', ...
                'N2-m_above_ground_Specific_humidity', ...
                'N2-m_above_ground_Temperature', ...
                'N10-m_above_ground_Zonal_wind_speed', ...
                'N10-m_above_ground_Meridional_wind_speed' ...
                };
    % latRange = [40.062999725341800,40.062999725341800];
    % lonRange = [-80.063003540039060,-80.063003540039060];
    % latRange = [40.1875, 40.9];
    % lonRange = [-80.3125, -79.5];
    latRange = [40.062999725341800,40.062999725341800];
    lonRange = [-80.063003540039060,-80.063003540039060];

    useConstOffset = 1;

    % 
    %Downloading data (only run when needed!)
    % for day = days
    %    downloadDataForDay(year, day);
    % end

    %LOADING FROM DISK: Note that commenting this out once Xraw is loaded is a useful debugging speed boost.
    % Xraw = loadData(varNames, latRange, lonRange, year, days, hours);

    %Or, load a previously saved version
    load 'Xraw.mat';

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
end

X = Xraw;

%Data whitening
%Source: http://metaoptimize.com/qa/questions/4985/what-exactly-is-whitening
% M = mean(Xraw);
% X = bsxfun(@minus, X, M); %shift to 0-mean
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
% stdXRaw = std(Xraw);
% X = bsxfun(@rdivide, X, stdXRaw);

%Diffs (for removing trends)
% X = diff(X,1);

%DEBUGGING ONLY
% X = X(1:20,:);

%Splice out any variables which we don't wish to include in the model
varsOfInterest = 1:11;
blockSize = 1; %assumed # of cells in data (NOTE THE HARDCODING)
Xspliced = zeros(size(X,1), blockSize * length(varsOfInterest));
i = 1;
for varOfInterest = varsOfInterest
    Xspliced(:,1+blockSize*(i-1):blockSize*i) = X(:,1+blockSize*(varOfInterest-1):blockSize*varOfInterest);
    i = i + 1;
end
X = Xspliced;

%Split into training & testing data sets
pctOfDataForTraining = 0.2;
split = ceil(size(X,1) * pctOfDataForTraining);
Xtrain = X(1:split,:);
Xtest = X(split+1:end,:);

%DEBUGGING ONLY: Test set == training set
% Xtest = Xtrain;

%DEBUGGING ONLY: Actually, use full data set for training & reuse same for testing
% Xtest = X; Xtrain = X;

%Note: assuming that we've whitened the data, std devs should all just be
%1.0...but grab & use just in case we haven't whitened
stdX = std(X);

%Lag of the model (ie: how many prior timesteps to include in the model)
%This should be less than the # of timesteps in training data, or sadness
%will result.
ps = 1:10;

if (exist('pctErr')), clear pctErr; end
if (exist('absErr')), clear absErr; end
if (exist('avgPctErr')), clear avgPctErr; end

for p = ps 
    %Train the model
    Pi{p} = trainVAR(Xtrain,p,useConstOffset);

    %Test forecasting accuracy
    XtestN = size(Xtest,1);
    for i = 1:XtestN
        Xactual(i,:) = Xtest(i,:);
        
        if (i < p + 1)
            %Just dup the true data until we have enough history for the lag order to start making predictions
            Xpred(i,:) = Xtest(i,:);
        else
            % %"Hard" version: Forecast many steps based on own previous estimates
%             Xpred(i,:) = predVAR(Pi{p}, Xpred(i-p:i-1,:), useConstOffset);
            
            %"Easy" version: Forecast one step ahead based on real historical data
            Xpred(i,:) = predVAR(Pi{p}, Xactual(i-p:i-1,:), useConstOffset);
        end
        
        Xerr(i,:) = Xpred(i,:) - Xactual(i,:);

        err(p,i,:) = Xerr(i,:);
        %pctErr(p,i,:) = Xerr(i,:) ./ stdX;
    end
    
    %Note that we cut the initial p steps from the performance estimate,
    %since those are just directly copied values from the test set
%     avgPctErr(p) = mean2(pctErr(p,(p+1):end,:));
    avgPctErr(p,:) = sqrt(mean(squeeze(err(p,(p+1):end,:)).^2)) ./ stdX;
%     avgAbsErr(p) = mean2(absErr(p,(p+1):end,:));
    disp(['Avg test error pct for lag p = ', num2str(p), ': ', num2str(avgPctErr(p))]);
%     disp(['Avg absolute test error for lag p = ', num2str(p), ': ', num2str(avgAbsErr(p))]);
end


%Test error vs. lag order
avgPctErrAcrossVars = mean(avgPctErr,2);
xMin = ps(1); xMax = ps(end); yMin = 0; yMax = 1;
plot(avgPctErrAcrossVars, 'LineWidth', 5);
% firstQuartileErrs       = prctile(avgPctErr, 25, 2);
% thirdQuartileErrs       = prctile(avgPctErr, 75, 2);
% %Returned handles: struct w/ mainLine, patch, and edge[2]
% plotH = shadedErrorBar(ps, avgPctErrAcrossVars', [thirdQuartileErrs'; firstQuartileErrs'], '-r', 0);
% set(plotH.mainLine, 'LineWidth', 4);
% title(sprintf('Training Error'));
title(sprintf('Test Error'));
xlabel('Lag Order');
ylabel(sprintf('Normalized RMS Error'));
axis([xMin xMax yMin yMax]);
set(gca, 'XTick', 0:1:xMax);
% set(gca, 'YTick', [yMin::yMax]);
box off;
sdf('10_701'); %apply our style (make sure it exists on your machine!)

end

