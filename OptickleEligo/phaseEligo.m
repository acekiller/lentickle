function opt = phaseEligo(opt,pos)
    
    f0 = 150;
    
    % construct arguments for setDemodPhases
    
    Ndrive = opt.Ndrive;
    
    nPR = getDriveNum(opt,'PR');
    nEX = getDriveNum(opt,'EX');
    nEY = getDriveNum(opt,'EY');
    
    % primary probes to tune
    
    AS_Q.name = 'AS Q1';
    AS_Q.compName = 'AS I1';
    AS_Q.IorQ = 'Q';
    AS_Q.dof = 'DARM';
    
    REFL1_I.name = 'REFL I1';
    REFL1_I.compName = 'REFL Q1';
    REFL1_I.IorQ = 'I';
    REFL1_I.dof = 'CARM';
    
    REFL2_I.name = 'REFL I2';
    REFL2_I.compName = 'REFL Q2';
    REFL2_I.IorQ = 'I';
    REFL2_I.dof = 'CARM';
    
    POX_I.name = 'POX I1';
    POX_I.compName = 'POX Q1';
    POX_I.IorQ = 'I';
    POX_I.dof = 'PRC';
    
    iSensor = 0;
    
    sensList = [ AS_Q REFL1_I REFL2_I POX_I ];
    mIQ{length(sensList),3} = '';
    mDOF = zeros(length(sensList),Ndrive);
    
    for sensor = sensList
        iSensor = iSensor + 1;
        
        mIQ{iSensor,1} = sensor.name;
        mIQ{iSensor,2} = sensor.compName;
        mIQ{iSensor,3} = sensor.IorQ;
        
        % build the DOF drive matrix for tuning sensors
        for jDrive = 1:Ndrive
            switch sensor.dof
                case 'DARM'
                    switch jDrive
                        case nEX
                            mDOF(iSensor,jDrive) =  1;
                        case nEY
                            mDOF(iSensor,jDrive) = -1;
                    end
                case 'CARM'
                    switch jDrive
                        case nEX
                            mDOF(iSensor,jDrive) = 1;
                        case nEY
                            mDOF(iSensor,jDrive) = 1;
                    end
                case 'PRC'
                    switch jDrive
                        case nPR
                            mDOF(iSensor,jDrive) = 1;
                    end
            end 
        end    
    end
    
    % tune phases
    opt = setDemodPhases(opt,mIQ,mDOF,pos,f0);
    
end