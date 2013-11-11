%Just scratch scripts so we don't forget useful stuff

%Loading & viewing pressure for one GRB file
nc=ncgeodataset('./hydro1.sci.gsfc.nasa.gov/data/s4pa/NLDAS/NLDAS_FORA0125_H.002/2007/001/NLDAS_FORA0125_H.A20070101.0000.002.grb');
dirvar = nc.geovariable('Pressure');
dir=dirvar.data(1,:,:);
g=dirvar.grid_interop(1,:,:);

%Grab grid indices for lat/long ranges
%Assumes 'g' is a struct w/ lat and lon fields, each being an array for that axis
latRange = [35 45];
lonRange = [-85 -75];
latIndices = find(g.lat > latRange(1) & g.lat < latRange(2));
lonIndices = find(g.lon > lonRange(1) & g.lon < lonRange(2));