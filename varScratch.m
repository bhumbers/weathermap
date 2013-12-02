%function [ Xpred, Xactual] = varScratch()
%VARSCRATCH Scratch testing function for our VAR model

%Training data specifications
% year = 2010;
% days = 258:268;
% hours= 0:23;
% % varNames = {'N2-m_above_ground_Temperature', 'Pressure', 'N10-m_above_ground_Meridional_wind_speed', 'N2-m_above_ground_Specific_humidity'};
% varNames = {'Pressure'};
% latRange = [40,41];
% lonRange = [-80, -79];
year = 2010;
days = 258:260;
hours= 0:23;
varNames = {'Precipitation_hourly_total', 'Pressure', 'N2-m_above_ground_Temperature'};
latRange = [40.062999725341800,40.062999725341800];
lonRange = [-80.063003540039060,-80.063003540039060];
% latRange = [40,41];
% lonRange = [-80, -79];

useConstOffset = 1;

% 
% % %Downloading data (only run when needed!)
% % for day = days
% %    downloadDataForDay(year, day);
% % end
% 

%LOADING FROM DISK: Note that commenting this out once Xraw is loaded is a useful debugging speed boost.
% Xraw = loadData(varNames, latRange, lonRange, year, days, hours);

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

%Split into training & testing data sets
pctOfDataForTraining = 0.5;
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
ps = 1;

if (exist('pctErr')), clear pctErr; end
if (exist('absErr')), clear absErr; end

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

%end

