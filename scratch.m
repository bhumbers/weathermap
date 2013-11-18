%Just scratch scripts so we don't forget useful stuff

%NOTE: To use the ncgeodataset stuff, run ./nctoolbox/setup_nctoolbox.m
%each time you boot up MATLAB

year = 2007;
days = [180:185];
hours=0:23;
varNames = {'N2-m_above_ground_Temperature'};
latRange = [40,41];%[40 45];
lonRange = [-80, -79];%[-85 -75];

%Downloading data (only run when needed!)
for day = days
   downloadDataForDay(year, day);
end

nVars = length(varNames);

p = 2;  %order of VAR lag
% n = ;   %length of total vector of variables for one timestep

for day = days
    for hour = hours 
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

            %For visualization debugging
            mv = mean2(varData(latIndices,lonIndices));
            mvs(hour+1) = mv;
            disp(['Mean value: ', num2str(mv)]);
            pcolorjw(double(varData(latIndices,lonIndices)));
            caxis([274 300]);
        end

        pause(0.1);
    end
end
   