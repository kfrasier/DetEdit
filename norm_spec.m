function [specNorm] = norm_spec(specSet,truncIDx)
% KE Frasier 05-19-2015

% Normalizes spectra by subtracting the slope between specified truncation
% indices (truncIDx), setting max amplitude to 1 and min amplitude to 0.

% Inputs: 
% specSet: An nxf matrix of detection spectra, where n is the number of
% spectra, and f is the number of frequencoes at which the spectra are
% evaluated.
% truncIdx: A 2 element vector containing the indices [low, high]
% between which to compute and subtract the spectral slope, and to 
% truncate the spectra. 

% Outputs:
% specNorm: An nxm matrix of detection spectra, where n is the number of
% spectra, and m is the number of frequencoes at which the spectra are
% evaluated between truncIdx(1) and truncIdx(2).

specSetTrunc = specSet(:, truncIDx(1):truncIDx(2));

alphaVec = specSetTrunc(:,end) - specSetTrunc(:,1);
slopeMat = zeros(size(specSetTrunc));
interpVal = size(specSetTrunc,2) - 1;
for it0 = 1:length(alphaVec)
    slopeMat(it0,:) = 0:alphaVec(it0)/interpVal:alphaVec(it0);
end
specSlopeNorm = specSetTrunc - slopeMat;

specMean = nanmean(specSlopeNorm);
specNormMin = specMean - min(specMean);
specNorm = specNormMin./max(specNormMin);
