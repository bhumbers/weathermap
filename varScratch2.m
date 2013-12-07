useSingleCellData = 1;
estimateVarsIndependently = 1;
useConstOffset = 1;
useLasso = 1;
varsOfInterest = 1:11;
lags = 1;
trainPct = 0.8;

%Load data
if useSingleCellData
    load 'Xraw.mat';  %Single-cell data
    blockSize = 1; %assumed # of cells in data (NOTE THE HARDCODING)
else
    load 'XrawFull.mat';    %All-cell data
    blockSize = 36; %assumed # of cells in data (NOTE THE HARDCODING) 
end

%Data whitening
X = Xraw;
M = mean(Xraw);
X = bsxfun(@minus, X, M); %shift to 0-mean
stdXRaw = std(Xraw);
X = bsxfun(@rdivide, X, stdXRaw);

%Chop down to variables of interest only
Xspliced = zeros(size(X,1), blockSize * length(varsOfInterest));
i = 1;
for varOfInterest = varsOfInterest
    Xspliced(:,1+blockSize*(i-1):blockSize*i) = X(:,1+blockSize*(varOfInterest-1):blockSize*varOfInterest);
    i = i + 1;
end
X = Xspliced;

%Split into training & testing data sets
pctOfDataForTraining = trainPct;
split = ceil(size(X,1) * pctOfDataForTraining);
Xtrain = X(1:split,:);
Xtest = X(split+1:end,:);

if estimateVarsIndependently
    i = 1;
    avgPctErr = zeros(size(varsOfInterest));
    for varOfInterest = varsOfInterest
        varCols = 1 + blockSize*(varOfInterest-1):blockSize*varOfInterest;
        XtrainSingleVar =  Xtrain(:,varCols);
        XtestSingleVar =    Xtest(:,varCols);
        avgPctErr(i) = doVAR(XtrainSingleVar, XtestSingleVar, lags, useConstOffset, useLasso);
        i = i+1;
    end
    avgPctErrAcrossVarsAndLags = mean2(avgPctErr);
    stdPctErrAcrossVarsAndLags = std2(avgPctErr);
else
    %Train & test the models for each lag
    [avgPctErr, Pi] = doVAR(Xtrain, Xtest, lags, useConstOffset, useLasso);
    avgPctErrAcrossVarsAndLags = mean2(avgPctErr);
    stdPctErrAcrossVarsAndLags = std2(avgPctErr);
end