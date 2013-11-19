
function [ X ] = loadData( varNames, latRange, lonRange, year, days, hours)
%LOADDATA Loads GRB files into a data matrix
%   OUTPUT: X is an T x N vector, where N is the number of distinct variables per
%               timestep, T is the number of timesteps used for training.
%       T and N depend on the grid resolution of each variable field
%       requested. 

%NOTE: Would be nice to pre-allocate X here, but we're not really sure how
%large it will be until we read each field...

xRow = 1; %rows correspond to time steps
T = length(days) * length(hours);
for day = days
    for hour = hours 
        %Each block of columns corresponds to reshaped (vectorized) grid values of one variable type
        xCol = 1;  
        
        disp(['Loading data for hour ', num2str(hour)]);

        %Load GRB file for a single hour timestep
        dateNumYearStart = datenum([2007, 0, 0, 0, 0, 0]); 
        dateNum = dateNumYearStart + day;
        [~, month, monthDay, ~, ~, ~] = datevec(dateNum);

        fileName = ['./hydro1.sci.gsfc.nasa.gov/data/s4pa/NLDAS/NLDAS_FORA0125_H.002/', ...
                                num2str(year), '/', sprintf('%03d', day), '/NLDAS_FORA0125_H.A', ...
                                sprintf('%d%02d%02d',year,month,monthDay), '.',...
                                sprintf('%02d', hour), '00.002.grb'];
        nc=ncgeodataset(fileName);

        %Grab variables of interest
        for varName = varNames
            var = nc.geovariable(varName{1});
            varData     = squeeze(var.data(1,:,:));
            varData(~isfinite(varData)) = 0;
            varGrid     = var.grid_interop(1,:,:);

            %Grab grid indices for lat/long ranges
            %Assumes 'varGrid' is a struct w/ lat and lon fields, each being an array for that axis
            latIndices = find(varGrid.lat > latRange(1) & varGrid.lat < latRange(2));
            lonIndices = find(varGrid.lon > lonRange(1) & varGrid.lon < lonRange(2));

            %Add this grid of values into total data array
            dataSegment = varData(latIndices,lonIndices);
            n = numel(dataSegment);
            X(xRow, xCol:xCol+n-1) = reshape(dataSegment, 1, n); 
            xCol = xCol + n;
        end
    
        %Once we've filled in the first timestep row, we know how much
        %space will be needed for X, so preallocate the rest
        if (xRow == 1)
            X(2:T,:) = zeros(T-1, length(X(1,:)));
        end
        
        xRow = xRow + 1;
    end
end

end

