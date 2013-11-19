% % function [ Xpred, Xactual] = varScratch()
% % %VARSCRATCH Scratch testing function for our VAR model
% 
% %Training data specifications
% year = 2007;
% days = 181:184;
% hours= 0:23;
% varNames = {'N2-m_above_ground_Temperature', 'Pressure'};
% latRange = [40,41];
% lonRange = [-80, -79];
% 
% %Downloading data (only run when needed!)
% % for day = days
% %    downloadDataForDay(year, day);
% % end
% 
% X = loadData(varNames, latRange, lonRange, year, days, hours);
% 
% %Remove mean vals, make unit std devs
% X = bsxfun(@minus, X, mean(X));
% X = bsxfun(@rdivide, X, std(X));
% 
% split = size(X,1)/2;
% Xtrain = X(1:split,:);
% Xtest = X(split+1:end,:);

%Lag of the model (ie: how many prior timesteps to include in the model)
%This should be less than the # of timesteps in training data, or sadness
%will result.
ps = 1:5;

for p = ps 
    %Train the model
    Pi{p} = trainVAR(Xtrain,p);

    %Test forecasting accuracy
    XtestN = size(Xtest,1);
    for i = p+1:XtestN
        Xactual = Xtest(i,:);
        Xpred = predVAR(Pi{p}, Xtest(i-p:i-1,:));
        Xerr = Xpred - Xactual;

        pctErr(i,:) = abs(Xerr ./ Xactual);
    end
    
    avgPctErr = mean2(pctErr);
    disp(['Avg test error pct for lag p = ', num2str(p), ': ', num2str(avgPctErr)]);
end

% end

