function [specNorm] = norm_spec(specSet,truncVals)

specSetTrunc = specSet(:, truncVals(1):truncVals(2));

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
