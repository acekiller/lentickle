function lentickle = lentickleEligo(opt)
% Defines matricies and filters for lentickle model 
% The matrices defined here are:

% probeSens - from optickle probes to the sensors used
% sensDof   - from sensors to dof, it is the inverse of the sensing matrix in fileSensNEW
% ctrlFilt  - control filters used for each dof
% dofMirr   - from dof to mirrors
% mirrFilt - additional filters to take into account for differences between the mirrors
% pendFilt - pendulum TF for each mirror (from penultimum mass actuator to mirror motion);
% mirrDrive - map from mirrors to Optickle drive indeces

% optickle probe serial numbers of relevant sensors
nASI =  getProbeNum(opt, 'AS_A I1');
nASQ =  getProbeNum(opt, 'AS_A Q1');
nPOXI =  getProbeNum(opt, 'POX_A I1');
nPOXQ =  getProbeNum(opt, 'POX_A Q1');
nREF1I =  getProbeNum(opt, 'REFL_A I1');
nREF1Q =  getProbeNum(opt, 'REFL_A Q1');
nREF2I =  getProbeNum(opt, 'REFL_A I2');
nREF2Q =  getProbeNum(opt, 'REFL_A Q2');
nOMCPD =  getProbeNum(opt, 'OMCt_A DC');

% reduced sensor set simple names
pp.sensNames = {'AS_I','AS_Q','POX_I','POX_Q','REFL1_I','REFL1_Q',...
                'REFL2_Q','REFL2_I','OMC_PD'};


% get the serial numbers of optics
pp.mirrNames = {'EX', 'EY', 'IX', 'IY', 'BS','PR','AM','PM'};

pp.Nmirr = numel(pp.mirrNames);
pp.vMirr = zeros(1, pp.Nmirr);
pp.driveMirr = sparse(pp.Nmirr, opt.Ndrive);
for n=1:pp.Nmirr
  pp.vMirr(n) = getDriveIndex(opt, pp.mirrNames{n});
  pp.driveMirr(n, pp.vMirr(n)) = 1;
end

% Degrees of freedom in the control basis
pp.dofNames = {'DARM','MICH','PRC','CM'};
pp.Ndof = numel(pp.dofNames);

% index of each DOF, by name
for n = 1:pp.Ndof
  pp.(pp.dofNames{n}) = n;
end

% drive matrix (LSC output matrix)
d = sqrt(2)/2;
%                    DARM MICH PRC CM
pp.dofMirr =       [  1    0    0   0  ; %EX
                     -1    0    0   0  ; %EY
                      0    0    0   0  ; %IX
                      0    0    0   0  ; %IY
                      0    1    0   0  ; %BS
                      0   -d    1   0  ; %PR
                      0    0    0   0  ; %AM
                      0    0    0   1 ]; %PM
                          
pp.mirrDrive = pp.driveMirr';
pp.dofDrive  = pp.mirrDrive * pp.dofMirr;
pp.mirrDof   = pinv(pp.dofMirr); %changed inv to pinv
pp.driveDof  = pp.mirrDof * pp.driveMirr ;

% Control Loop input ports and input matrix
pp.vSens = [nASI,nASQ,nPOXI,nPOXQ,nREF1I,nREF1Q,nREF2I,nREF2Q,nOMCPD];

pp.probeName = getProbeName(opt, pp.vSens);
for n = 1 : pp.Ndof
pp.nameDC(n) = regexprep(pp.probeName(n), ' (\w*)', ' DC');
pp.nsigDC(n) = getProbeNum(opt, pp.nameDC{n});
end

pp.Nsens = length(pp.vSens);
pp.probeSens = sparse(pp.Nsens, opt.Nprobe);
for n=1:pp.Nsens
  pp.probeSens(n, pp.vSens(n)) = 1;
end

% input matrix
%              DARM MICH PRC CM
pp.dofSens = [  0    0    0   0  ; %ASI
                0    0    0   0  ; %ASQ
                0    0    1   0  ; %POXI
                0    1    0   0  ; %POXQ
                0    0    0   1  ; %REFL1I
                0    0    0   0  ; %REFL1Q
                0    0    0   0  ; %REFL2I
                0    0    0   0  ; %REFL2Q
                1    0    0   0  ];%OMCPD_SUM

               % DARM       MICH   PRC       CM 
pp.gainDof = [ -.483    137   1.82e8   -1e7]; 

pp.sensDof_temp = pinv(pp.dofSens); %pinv

for n = 1 : pp.Ndof
  pp.sensDof(n,:) = pp.gainDof(n) .* pp.sensDof_temp(n,:); %%%bug here (n) argument on gainSens
end
                 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Specify the control loop filters (to be tuned)

pp.ctrlDARM =...  %from foton
    filtZPK([3.13147-1i*5.118;3.13147+1i*5.118;0.397453-1i*11.9034;...
    0.397453+1i*11.9034;1.6224-1i*16.106;1.6224+1i*16.106;...
    0.436471-1i*17.4345;0.436471+1i*17.4345;0.443239-1i*17.5444;...
    0.443239+1i*17.5444;0.441977-1i*17.6545;0.441977+1i*17.6545;...
    8.2249-1i*15.6821;8.2249+1i*15.6821;8.03813+1i*16.2668;...
    8.03813-1i*16.2668;1.87622-1i*18.6257;1.87622+1i*18.6257;16-1i*27.7129;...
    16+1i*27.7129;3.60782-1i*34.6879;3.60782+1i*34.6879;10;100;100],...
    [0.313147-1i*5.99182;0.313147+1i*5.99182;4.04244-1i*4.88795;...
    4.04244+1i*4.88795;0.0125686-1i*11.91;0.0125686+1i*11.91;...
    1.67444+1i*11.8005;1.67444-1i*11.8005;0.0513048+1i*16.1874;...
    0.0513048-1i*16.1874;0.0138024+1i*17.44;0.0138024-1i*17.44;...
    0.0443239+1i*17.5499;0.0443239-1i*17.5499;0.0139765-1i*17.66;...
    0.0139765+1i*17.66;0.0593314+1i*18.7199;0.0593314-1i*18.7199;...
    0.641572+1i*34.8691;0.641572-1i*34.8691;443.007-1i*896.518;...
    443.007+1i*896.518;2828.43+1i*2828.43;2828.43-1i*2828.43;0;0;200],...
    13130.1);

pp.ctrlMICH = ... %from foton
    filtZPK([0.652205+i*0.983376;0.652205-i*0.983376;0.759539+i*1.95783;0.759539-i*1.95783;10+i*17.3205;...
    10-i*17.3205;0+i*329.395;0-i*329.395;0+i*329.584;0-i*329.584;0+i*329.773;0-i*329.773;1;3],...
    [0.163827+i*1.16857;0.163827-i*1.16857;0.190788+i*2.09132;0.190788-i*2.09132;4.82796+i*10.8438;...
    4.82796-i*10.8438;88.6014+i*179.304;88.6014-i*179.304;0.207419+i*329.031;0.207419-i*329.031;...
    0.75946+i*329.583;0.75946-i*329.583;0.208118+i*330.138;0.208118-i*330.138;0],2.83899);

pp.ctrlPRC = ... %from foton
    filtZPK([0.255452-i*1.20318;0.255452+i*1.20318;1.34397-i*6.10379;1.34397+i*6.10379;2.41535-i*6.57009;...
    2.41535+i*6.57009;0.394014+i*11.6934;0.394014-i*11.6934;0.40075+i*11.8933;0.40075-i*11.8933;...
    0.61386+i*12.1345;0.61386-i*12.1345;0.417588+i*12.393;0.417588-i*12.393;0.424323-i*12.5929;...
    0.424323+i*12.5929;0.431058-i*12.7927;0.431058+i*12.7927;0.454604-i*17.9943;0.454604+i*17.9943;...
    10+i*18;10-i*18;0+i*329.395;0-i*329.395;0+i*329.584;0-i*329.584;0+i*329.773;0-i*329.773;1;5;7],...
    [0.0454266-i*1.22916;0.0454266+i*1.22916;0.33759-i*6.24088;0.33759+i*6.24088;0.341177-i*6.99168;...
    0.341177+i*6.99168;1.43751-i*11.4098;1.43751+i*11.4098;0.0394014-i*11.6999;0.0394014+i*11.6999;...
    0.040075+i*11.8999;0.040075-i*11.8999;0.061386+i*12.1498;0.061386-i*12.1498;0.0417588+i*12.3999;...
    0.0417588-i*12.3999;0.0424323+i*12.5999;0.0424323-i*12.5999;0.0431058-i*12.7999;...
    0.0431058+i*12.7999;0.0454604+i*17.9999;0.0454604-i*17.9999;0.207419+i*329.031;...
    0.207419-i*329.031;0.75946-i*329.583;0.75946+i*329.583;0.208118+i*330.138;0.208118-i*330.138;...
    707.107-i*707.107;707.107+i*707.107;1350.43-i*1350.43;1350.43+i*1350.43;0;1],22.4437);

pp.ctrlCM = filtProd(filtZPK([1,1,1],[0,0,0,0,0],1),filtZPG([1e3,1e3],[0,0],1,2e5)); %simple for now
%%% filtZPG
pp.ctrlFilt = [pp.ctrlDARM, pp.ctrlMICH, pp.ctrlPRC, pp.ctrlCM];

% Specify the pendulum TF (mechanical response) and treat PM as a frequency
% actuator

pp.unityFilt = filtZPK([],[],1);

pp.pend = filtZPG([], filtRes(0.7, 50.0025), 1, 0);

pp.integrator = filtZPK([0],[],1);
 
pp.pendFilt = [pp.pend, pp.pend, pp.pend, pp.pend, pp.pend, pp.pend, pp.unityFilt, pp.integrator];

% mirrFilt defines compensation filters (approximating the inverse of the
% mechanical response). This type of control design was not used in iLIGO.

pp.mirrFilt = [pp.unityFilt,pp.unityFilt,pp.unityFilt,pp.unityFilt,pp.unityFilt,pp.unityFilt,pp.unityFilt,pp.unityFilt];

% Put opt and all the parameters in lentickle
lentickle.param = pp;
lentickle.opt = opt; 