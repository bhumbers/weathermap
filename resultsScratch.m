testParams = struct;

%Load data
useSingleCellData = 0;
if useSingleCellData
    load 'Xraw.mat';  %Single-cell data
    testParams.numCellsX = 1;
    testParams.numCellsY = 1;
else
    load 'XrawFull.mat';    %All-cell data
    testParams.numCellsX = 6;
    testParams.numCellsY = 6;
end

testParams.reportTrainingResults = 1;
testParams.reportTestResults = 1;
testParams.useConstOffset = 1;
testParams.useLasso = 0;
testParams.varsOfInterest = 1:11;
testParams.lags = 1:2;
testParams.trainPct = 0.2;
testParams.Xraw = Xraw;

[ PiByLag, testResults, trainResults] = varScratch2(testParams);


% figure;
% plot([testResults.avgPctErrByLag{1}', trainResults.avgPctErrByLag{1}']);


%Get average error across cells for each variable
numCells = testParams.numCellsX * testParams.numCellsY;
numVars = length(testParams.varsOfInterest);
avgTestPctErrByLagAcrossCells = cell(length(testParams.lags), 1);
avgTrainPctErrByLagAcrossCells = cell(length(testParams.lags), 1);
for lag=testParams.lags
    colsForVar = 1:numCells;
    i = 1;
    while (i <= numVars)
        testPctErrs = testResults.avgPctErrByLag{lag}(1 + (i-1)*numCells:i*numCells);
        avgTestPctErrByLagAcrossCells{lag}(i) = mean(testPctErrs);
        
        trainPctErrs = trainResults.avgPctErrByLag{lag}(1 + (i-1)*numCells:i*numCells);
        avgTrainPctErrByLagAcrossCells{lag}(i) = mean(trainPctErrs);
        
        i = i + 1;
    end
end


avgPctErrs = {testResults.avgPctErrByLag, trainResults.avgPctErrByLag};
graphTitles = {'Test Error', 'Training Error'};
for i = 1:size(avgPctErrs, 2)
    avgPctErr = avgPctErrs{i};
    graphTitle = graphTitles{i};
    figure;
    testErrsByLagMatrix = [];
    lagLabels = [];
    for lag=testParams.lags
       testErrsByLagMatrix = [testErrsByLagMatrix, avgPctErr{lag}'];
       lagLabels = [lagLabels; ['Lag ', num2str(lag)]];
    end
    plot(testErrsByLagMatrix); 
    legend(lagLabels);
%     axis([-Inf, Inf, 0, 1]);
%     set(gca,'XTick', testParams.varsOfInterest)
    title(graphTitle);
    xlabel('System Variable (weather var x cell location)');
    ylabel('RMS Error');
end

