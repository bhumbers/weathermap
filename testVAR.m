function [ avgPctErr, Xpred ] = testVAR( Pi, Xtest, useConstOffset)

XtestT = size(Xtest,1);
N = size(Xtest,2);
k = size(Pi,1);
if (useConstOffset) 
    p = (k-1) / N;
else
    p = k / N;
end

%Note: assuming that we've whitened the data, std devs should all just be
%1.0...but grab & use just in case we haven't whitened
stdX = std(Xtest);

%Test forecasting accuracy
Xpred = zeros(XtestT, N);
Xerr = zeros(XtestT, N);
for i = 1:XtestT
    if (i < p + 1)
        %Just dup the true data until we have enough history for the lag order to start making predictions
        Xpred(i,:) = Xtest(i,:);
    else
        % %"Hard" version: Forecast many steps based on own previous estimates
%         Xpred(i,:) = predVAR(Pi, Xpred(i-p:i-1,:), useConstOffset);

        %"Easy" version: Forecast one step ahead based on real historical data
        Xpred(i,:) = predVAR(Pi, Xtest(i-p:i-1,:), useConstOffset);
    end

    Xerr(i,:) = Xpred(i,:) - Xtest(i,:);
end
    
%Note that we cut the initial p steps from the performance estimate,
%since those are just directly copied values from the test set

avgPctErr = sqrt(mean(squeeze(Xerr((p+1):end,:).^2))) ./ stdX; %RMS error
end

