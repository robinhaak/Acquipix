function vecSphereVector = PH_BregmaVec2SphVec(vecBregmaVector,sAtlas)
	%PH_BregmaVec2SphVec Calculates coordinates in atlas volume for bregma-centered Paxinos
	%				coordinates of brain entry, probe depth in microns and ML and AP angles in degrees
	%   vecSphereVector = PH_BregmaVec2SphVec(vecBregmaVector,sAtlas)
	%
	%In Paxinos coordinates, coordinates relative to bregma (bregma - X) mean that -AP is posterior,
	%+AP is anterior, -DV is dorsal, +DV is ventral
	%matCartVector = [x1 y1 z1; x2 y2 z2], where [x1 y1 z1] is probe tip
	%vecSphereVector = [x1 y1 z1 deg-ML deg-AP length]
	%
	%bregma vector is 6-element vector: [ML AP ML-deg AP-deg depth length], with ML and AP being brain
	%entry coordinates relative to bregma in microns, ML-deg and AP-deg the probe angles in degrees,
	%and depth is the depth in microns of the tip of the probe from the brain entry point. Note that
	%the DV coordinates in the bregma-vector system are therefore inferred from the other
	%parameters. The sixth element is the length of the probe in microns.
	
	%transform to atlas space
	dblAtlasML = sAtlas.Bregma(1) + (vecBregmaVector(1) / sAtlas.VoxelSize(1));
	dblAtlasAP = sAtlas.Bregma(2) + (vecBregmaVector(2) / sAtlas.VoxelSize(2));
	dblAngleML_deg = vecBregmaVector(3);
	dblAngleAP_deg = vecBregmaVector(4);
	dblDepthAtlas = vecBregmaVector(5) / sAtlas.VoxelSize(end); %only valid if voxels are isometric
	dblLengthAtlas = vecBregmaVector(6) / sAtlas.VoxelSize(end); %only valid if voxels are isometric
	
	%calculate tip location relative to entry
	[dX,dY,dZ] = sph2cart(deg2rad(dblAngleAP_deg),deg2rad(dblAngleML_deg+90),dblDepthAtlas);
	
	%find highest point of brain at these ML,AP coordinates
	vecBrainEntry = vecBregmaVector(1:3) + sAtlas.Bregma;
	if dZ < 0
		intDV = find(sAtlas.av(vecBrainEntry(1),vecBrainEntry(2),:) > 1,1,'first');
	else
		intDV = find(sAtlas.av(vecBrainEntry(1),vecBrainEntry(2),:) > 1,1,'last');
	end
	vecTipLoc = [dblAtlasML-dX dblAtlasAP-dY intDV-dZ];
	
	%compile
	vecSphereVector = nan(1,6);
	vecSphereVector(1:3) = vecTipLoc;
	vecSphereVector(4) = dblAngleML_deg;
	vecSphereVector(5) = dblAngleAP_deg;
	vecSphereVector(6) = dblLengthAtlas;
end

