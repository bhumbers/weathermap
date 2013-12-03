function [ avgPctErr ] = doVAR( X, ps, trainPct)

useConstOffset = 1;

%Split into training & testing data sets
pctOfDataForTraining = trainPct;
split = ceil(size(X,1) * pctOfDataForTraining);
Xtrain = X(1:split,:);
Xtest = X(split+1:end,:);

%DEBUGGING ONLY: Test set == training set
Xtest = Xtrain;

%DEBUGGING ONLY: Actually, use full data set for training & reuse same for testing
% Xtest = X; Xtrain = X;

%Note: assuming that we've whitened the data, std devs should all just be
%1.0...but grab & use just in case we haven't whitened
stdX = std(X);

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

end

