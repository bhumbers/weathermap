
%Test errors are put in results column 1, training in column 2 (if requested)
function [ PiByLag, testResults, trainResults] = varScratch2(testParams) 

Xraw = testParams.Xraw;
numCells = testParams.numCellsX * testParams.numCellsY;

%Data whitening
X = Xraw;
M = mean(Xraw);
X = bsxfun(@minus, X, M); %shift to 0-mean
stdXRaw = std(Xraw);
X = bsxfun(@rdivide, X, stdXRaw);

%Chop down to variables of interest only
Xspliced = zeros(size(X,1), numCells * length(testParams.varsOfInterest));
i = 1;
for varOfInterest = testParams.varsOfInterest
    Xspliced(:,1+numCells*(i-1):numCells*i) = X(:,1+numCells*(varOfInterest-1):numCells*varOfInterest);
    i = i + 1;
end
X = Xspliced;

%Split into training & testing data sets
split = ceil(size(X,1) * testParams.trainPct);
Xtrain = X(1:split,:);
Xtest = X(split+1:end,:);

testResults = struct;
trainResults = struct;

% if testParams.estimateVarsIndependently
%     i = 1;
%     avgPctErr = zeros(size(varsOfInterest));
%     for varOfInterest = varsOfInterest
%         varCols = 1 + numCells*(varOfInterest-1):numCells*varOfInterest;
%         XtrainSingleVar =  Xtrain(:,varCols);
%         XtestSingleVar =    Xtest(:,varCols);
%         avgPctErr(i) = doVAR(XtrainSingleVar, XtestSingleVar, lags, useConstOffset, useLasso);
%         i = i+1;
%     end
% else
    %Train & test the models for each lag
    for p = testParams.lags 
        PiByLag{p} = trainVAR(Xtrain, p, testParams.useConstOffset, testParams.useLasso);
        
        if (testParams.reportTestResults)
            [testResults.avgPctErrByLag{p}, testResults.XPredByLag{p} ] = testVAR(PiByLag{p}, Xtest, testParams.useConstOffset);
        end
        
        
        if (testParams.reportTrainingResults)
            [trainResults.avgPctErrByLag{p}, trainResults.XPredByLag{p} ] = testVAR(PiByLag{p}, Xtrain, testParams.useConstOffset);
        end
% end

end