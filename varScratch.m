%function [ Xpred, Xactual] = varScratch()
%VARSCRATCH Scratch testing function for our VAR model

%Training data specifications
% year = 2010;
% days = 258:260;
% hours= 0:23;
% varNames = {'N2-m_above_ground_Temperature', 'Pressure'};
% latRange = [40,41];
% lonRange = [-80, -79];
year = 2010;
days = 258:260;
hours= 0:23;
varNames = {'N2-m_above_ground_Temperature'};
latRange = [40.062999725341800,40.062999725341800];
lonRange = [-80.063003540039060,-80.063003540039060];

useConstOffset = 0;

% 
% % %Downloading data (only run when needed!)
% % for day = days
% %    downloadDataForDay(year, day);
% % end
% 
Xraw = loadData(varNames, latRange, lonRange, year, days, hours);

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
% debugN = 1;
% clear Xraw;
% for i=1:debugT
%    Xraw(i,:) = sin(i/20);
% end

X = Xraw;

%Data whitening
%Source: http://metaoptimize.com/qa/questions/4985/what-exactly-is-whitening
M = mean(X);
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

%Diffs
% X = diff(X,1);

%DEBUGGING ONLY
% X = X(1:20,:);

split = 10;%size(X,1)/2;
Xtrain = X(1:split,:);
Xtest = X(split+1:end,:);

%DEBUGGING, ONLY
% Xtest = X; Xtrain = X;

%Lag of the model (ie: how many prior timesteps to include in the model)
%This should be less than the # of timesteps in training data, or sadness
%will result.
ps = 2;

XtestVar = var(Xtest);

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
            %TODO: don't include this initial part in the performance estimates
            Xpred(i,:) = Xtest(i,:);
        else
            % %"Hard" version: Forecast many steps based on own previous estimates
%             Xpred(i,:) = predVAR(Pi{p}, Xpred(i-p:i-1,:), useConstOffset);
            
            %"Easy" version: Forecast one step ahead based on real historical data
            Xpred(i,:) = predVAR(Pi{p}, Xactual(i-p:i-1,:), useConstOffset);
        end
        
        Xerr(i,:) = Xpred(i,:) - Xactual(i,:);

        absErr(p,i,:) = abs(Xerr(i,:));
%         pctErr(i,:) = abs(Xerr(i-p,:) ./ Xactual(i-p,:));
        pctErr(p,i,:) = abs(Xerr(i,:) ./ XtestVar);
    end
    
    avgPctErr(p) = mean2(pctErr(p,:,:));
    avgAbsErr(p) = mean2(absErr(p,:,:));
    disp(['Avg test error pct for lag p = ', num2str(p), ': ', num2str(avgPctErr(p))]);
%     disp(['Avg absolute test error for lag p = ', num2str(p), ': ', num2str(avgAbsErr(p))]);
end

%end

