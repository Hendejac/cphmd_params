#!/usr/bin/env python
# Fit CpHMD parameters from CpHMD TI calculations
# 1) For Cys/Lys/Tyr: A B (fit_type: single)
# 2) For His: A0 B0 A1 B1 A10 B10 (fit_type: his)
# 3) For Asp/Glu: R1 R2 R3 R4 R5 R6 (fit_type: double)
# 4) Lambda file names should have the format <label>_<theta>[_<thetax>].lambda
# 5) Type 'cphmd_parm_fit.py -h' for usage

import sys
import glob
from scipy.optimize import leastsq
import numpy as np
import matplotlib.pyplot as plt

def fit_single(label, begin=0, end=-1):
    # 1) read lambda files and store theta and avereaged du/dtheta values in theta_list and du_dtheta_list
    theta_list = []
    du_dtheta_list = []
    for lfile in glob.glob("{}_*.lambda".format(label)):
        theta = lfile.split('_')[1][:-7]
        theta_list.append(float(theta))
        du_dtheta = []
        with open(lfile, 'r')  as lf:
            for line in lf:
                if line[0] != '#' and line[0] != '%':
                    values = line.split()
                    du_dtheta.append(float(values[2]))
        du_dtheta_list.append(np.mean(du_dtheta[begin:end]))
    dus = dict(zip(theta_list, du_dtheta_list))
    dus = {k: v for k, v in sorted(dus.items(), key=lambda x: x[0])}
    # 2) write to file
    with open('du.data', 'w') as tf:
        for theta in dus:
            tf.write('{:.4f}  {:11.8f}\n'.format(theta, dus[theta]))
            if (theta == 0.0 or theta == 1.5708) and dus[theta] > 0.0001:
                print('Warning: du/dtheta is {} for theta={}.\n'.format(dus[theta], theta))
                dus[theta] = 0.0    
    # 3) fit A and B
    errfunc_two_param = lambda p, x, y: fit_target_two_param(x, p) - y
    theta_list = np.array([theta for theta in dus])
    du_dtheta_list = np.array([dus[theta] for theta in dus])
    print(du_dtheta_list)
    pfit, pcov, infodict, errmsg, success = leastsq(errfunc_two_param, (-10, 0.5), \
            args=(theta_list, du_dtheta_list), full_output=1, epsfcn=0.000001)
    A = pfit[0]
    B = pfit[1]
    ssErr = (infodict['fvec']**2).sum()
    ssTot = ((du_dtheta_list-du_dtheta_list.mean())**2).sum()
    rsquared = 1-(ssErr/ssTot )
    with open('du.fit', 'w') as tf:
        tf.write('Fitting with formula: du/dtheta = 2*A*sin(2*theta)*(sin(theta)^2-B)\n')
        tf.write('Fitted results:\n')
        tf.write(' '*15 + 'A = {:.5f}\n'.format(pfit[0]))
        tf.write(' '*15 + 'B = {:.5f}\n'.format(pfit[1]))
        tf.write('Fitted errors:\n')
        tf.write(' '*11 + 'A_err = {:.5f}\n'.format(np.sqrt(pcov[0][0])))
        tf.write(' '*11 + 'B_err = {:.5f}\n'.format(np.sqrt(pcov[1][1])))
        tf.write('R squared: {:.6f}\n'.format(rsquared))
        tf.write('RMSE: {:.6f}\n'.format(np.sqrt(ssErr/len(theta_list))))
    x_exp = np.linspace(min(theta_list), max(theta_list), 40)
    y_exp = fit_target_two_param(x_exp, pfit)
    plot(theta_list, du_dtheta_list, x_exp, y_exp, rsquared, xlabel='theta', \
        ylabel='du/dtheta', file_name='du', label=None)
    # 4) save A and B to file
    with open('cphmd.parm', 'w') as tf:
        tf.write('A\t{:.6f}\n'.format(A))
        tf.write('B\t{:.6f}\n'.format(B))
        tf.write('Copy and paste the following line to the corresponding Cys/Lys/Tyr line in a CpHMD parm file:\n')
        tf.write('{:.6f},{:.6f},\n'.format(A,B))

def fit_his(label, begin=0, end=-1):
    # 1) read lambda files and store avereaged du/dtheta and du/dthetax values in dus
    dus = []  # element: (theta, thetax, mean_du_dtheta, mean_du_dthetax)
    for lfile in glob.glob("{}_*.lambda".format(label)):
        theta = lfile.split('_')[1]
        thetax = lfile.split('_')[2][:-7]
        du_dtheta = []
        du_dthetax = []
        with open(lfile, 'r')  as lf:
            for line in lf:
                if line[0] != '#' and line[0] != '%':
                    values = line.split()
                    du_dtheta.append(float(values[2]))
                    du_dthetax.append(float(values[4]))
        mean_du_dtheta = np.mean(du_dtheta[begin:end])
        mean_du_dthetax = np.mean(du_dthetax[begin:end])
        dus.append((theta, thetax, mean_du_dtheta, mean_du_dthetax))
        dus = sorted(dus, key=lambda x: (x[0], x[1]))
    # 2) output dus as to theta and thetax, both for files and arrays
    errfunc_two_param = lambda p, x, y: fit_target_two_param(x, p) - y
    # 2.1) for thetax=0.0, fit A0, B0
    theta_list = [0.0]
    du_dtheta_list = [0.0]
    with open('thetax-0.0-du.data', 'w') as tf:
        tf.write('{:.4f}  {:11.8f}\n'.format(0.0, 0.0))  # Fix theta=0.0 to have 0.0
    for du in dus:
        if du[1] == '0.0':
            theta_list.append(float(du[0]))
            du_dtheta_list.append(du[2])
            with open('thetax-0.0-du.data', 'a') as tf:
                tf.write('{:.4f}  {:11.8f}\n'.format(float(du[0]), du[2]))
    theta_list.append(float(du[0]))
    du_dtheta_list.append(0.0)
    with open('thetax-0.0-du.data', 'a') as tf:
        tf.write('{:.4f}  {:11.8f}\n'.format(1.5708, 0.0))  # Fix theta=1.5708 to have 0.0
    theta_list = np.array(theta_list)
    du_dtheta_list = np.array(du_dtheta_list)
    pfit, pcov, infodict, errmsg, success = leastsq(errfunc_two_param, (-10, 0.5), \
            args=(theta_list, du_dtheta_list), full_output=1, epsfcn=0.000001)
    A0 = pfit[0]
    B0 = pfit[1]
    ssErr = (infodict['fvec']**2).sum()
    ssTot = ((du_dtheta_list-du_dtheta_list.mean())**2).sum()
    rsquared = 1-(ssErr/ssTot )
    with open('thetax-0.0-du.fit', 'w') as tf:
        tf.write('Fitting with formula: du/dtheta = 2*A0*sin(2*theta)*(sin(theta)^2-B0)\n')
        tf.write('Fitted results:\n')
        tf.write(' '*15 + 'A0 = {:.5f}\n'.format(pfit[0]))
        tf.write(' '*15 + 'B0 = {:.5f}\n'.format(pfit[1]))
        tf.write('Fitted errors:\n')
        tf.write(' '*11 + 'A0_err = {:.5f}\n'.format(np.sqrt(pcov[0][0])))
        tf.write(' '*11 + 'B0_err = {:.5f}\n'.format(np.sqrt(pcov[1][1])))
        tf.write('R squared: {:.6f}\n'.format(rsquared))
        tf.write('RMSE: {:.6f}\n'.format(np.sqrt(ssErr/len(theta_list))))
    x_exp = np.linspace(min(theta_list), max(theta_list), 40)
    y_exp = fit_target_two_param(x_exp, pfit)
    plot(theta_list, du_dtheta_list, x_exp, y_exp, rsquared, xlabel='theta', \
        ylabel='du/dtheta', file_name='thetax-0.0-du', label='thetax = 0.0')
    # 2.2) for thetax=1.5708, fit A1, B1
    theta_list = [0.0]
    du_dtheta_list = [0.0]
    with open('thetax-1.5708-du.data', 'w') as tf:
        tf.write('{:.4f}  {:11.8f}\n'.format(0.0, 0.0))  # Fix theta=0.0 to have 0.0
    for du in dus:
        if du[1] == '1.5708':
            theta_list.append(float(du[0]))
            du_dtheta_list.append(du[2])
            with open('thetax-1.5708-du.data', 'a') as tf:
                tf.write('{:.4f}  {:11.8f}\n'.format(float(du[0]), du[2]))
    theta_list.append(float(du[0]))
    du_dtheta_list.append(0.0)
    with open('thetax-1.5708-du.data', 'a') as tf:
        tf.write('{:.4f}  {:11.8f}\n'.format(1.5708, 0.0))  # Fix theta=1.5708 to have 0.0
    theta_list = np.array(theta_list)
    du_dtheta_list = np.array(du_dtheta_list)
    pfit, pcov, infodict, errmsg, success = leastsq(errfunc_two_param, (-10, 0.5), \
            args=(theta_list, du_dtheta_list), full_output=1, epsfcn=0.000001)
    A1 = pfit[0]
    B1 = pfit[1]
    ssErr = (infodict['fvec']**2).sum()
    ssTot = ((du_dtheta_list-du_dtheta_list.mean())**2).sum()
    rsquared = 1-(ssErr/ssTot )
    with open('thetax-1.5708-du.fit', 'w') as tf:
        tf.write('Fitting with formula: du/dtheta = 2*A1*sin(2*theta)*(sin(theta)^2-B1)\n')
        tf.write('Fitted results:\n')
        tf.write(' '*15 + 'A1 = {:.5f}\n'.format(pfit[0]))
        tf.write(' '*15 + 'B1 = {:.5f}\n'.format(pfit[1]))
        tf.write('Fitted errors:\n')
        tf.write(' '*11 + 'A1_err = {:.5f}\n'.format(np.sqrt(pcov[0][0])))
        tf.write(' '*11 + 'B1_err = {:.5f}\n'.format(np.sqrt(pcov[1][1])))
        tf.write('R squared: {:.6f}\n'.format(rsquared))
        tf.write('RMSE: {:.6f}\n'.format(np.sqrt(ssErr/len(theta_list))))
    x_exp = np.linspace(min(theta_list), max(theta_list), 40)
    y_exp = fit_target_two_param(x_exp, pfit)
    plot(theta_list, du_dtheta_list, x_exp, y_exp, rsquared, xlabel='theta', \
        ylabel='du/dtheta', file_name='thetax-1.5708-du', label='thetax = 1.5708')
    # 2.3) for theta=1.5708, fit A10, B10
    thetax_list = [0.0]
    du_dthetax_list = [0.0]
    with open('theta-1.5708-du.data', 'w') as tf:
        tf.write('{:.4f}  {:11.8f}\n'.format(0.0, 0.0))  # Fix thetax=0.0 to have 0.0
    for du in dus:
        if du[0] == '1.5708':
            thetax_list.append(float(du[1]))
            du_dthetax_list.append(du[3])
            with open('theta-1.5708-du.data', 'a') as tf:
                tf.write('{:.4f}  {:11.8f}\n'.format(float(du[1]), du[3]))
    with open('theta-1.5708-du.data', 'a') as tf:
        tf.write('{:.4f}  {:11.8f}\n'.format(1.5708, 0.0))  # Fix thetax=1.5708 to have 0.0
    thetax_list.append(float(du[0]))
    du_dthetax_list.append(0.0)
    thetax_list = np.array(thetax_list)
    du_dthetax_list = np.array(du_dthetax_list)
    pfit, pcov, infodict, errmsg, success = leastsq(errfunc_two_param, (-10, 0.5), \
            args=(thetax_list, du_dthetax_list), full_output=1, epsfcn=0.000001)
    A10 = pfit[0]
    B10 = pfit[1]
    ssErr = (infodict['fvec']**2).sum()
    ssTot = ((du_dthetax_list-du_dthetax_list.mean())**2).sum()
    rsquared = 1-(ssErr/ssTot )
    with open('theta-1.5708-du.fit', 'w') as tf:
        tf.write('Fitting with formula: du/dthetax = 2*A10*sin(2*thetax)*(sin(thetax)^2-B10)\n')
        tf.write('Fitted results:\n')
        tf.write(' '*15 + 'A10 = {:.5f}\n'.format(pfit[0]))
        tf.write(' '*15 + 'B10 = {:.5f}\n'.format(pfit[1]))
        tf.write('Fitted errors:\n')
        tf.write(' '*11 + 'A10_err = {:.5f}\n'.format(np.sqrt(pcov[0][0])))
        tf.write(' '*11 + 'B10_err = {:.5f}\n'.format(np.sqrt(pcov[1][1])))
        tf.write('R squared: {:.6f}\n'.format(rsquared))
        tf.write('RMSE: {:.6f}\n'.format(np.sqrt(ssErr/len(thetax_list))))
    x_exp = np.linspace(min(thetax_list), max(thetax_list), 40)
    y_exp = fit_target_two_param(x_exp, pfit)
    plot(thetax_list, du_dthetax_list, x_exp, y_exp, rsquared, xlabel='thetax', \
        ylabel='du/dthetax', file_name='theta-1.5708-du', label='theta = 1.5708')
    # 2.4) save A0, B0, A1, B1, A10, B10 to file
    with open('cphmd.parm', 'w') as tf:
        tf.write('A0\t{:.6f}\n'.format(A0))
        tf.write('B0\t{:.6f}\n'.format(B0))
        tf.write('A1\t{:.6f}\n'.format(A1))
        tf.write('B1\t{:.6f}\n'.format(B1))
        tf.write('A10\t{:.6f}\n'.format(A10))
        tf.write('B10\t{:.6f}\n\n'.format(B10))
        tf.write('Copy and paste the following line to the corresponding His line in a CpHMD parm file:\n')
        tf.write('{:.6f},{:.6f},{:.6f},{:.6f},{:.6f},{:.6f},\n'.format(A0,B0,A1,B1,A10,B10))

def fit_double(label, begin=0, end=-1):
    # 1) read lambda files and store avereaged du/dtheta and du/dthetax values in dus
    dus = []  # element: (theta, thetax, mean_du_dtheta, mean_du_dthetax)
    for lfile in glob.glob("{}_*.lambda".format(label)):
        theta = lfile.split('_')[1]
        thetax = lfile.split('_')[2][:-7]
        du_dtheta = []
        du_dthetax = []
        with open(lfile, 'r')  as lf:
            for line in lf:
                if line[0] != '#' and line[0] != '%':
                    values = line.split()
                    du_dtheta.append(float(values[2]))
                    du_dthetax.append(float(values[4]))
        mean_du_dtheta = np.mean(du_dtheta[begin:end])
        mean_du_dthetax = np.mean(du_dthetax[begin:end])
        if thetax == '0.0' or thetax == '1.5708':
            if abs(mean_du_dthetax) < 1e-4:
                mean_du_dthetax = 0.0
            else:
                print("Warning: du/dthetax for theta={} and thetax={} is {}.".format(theta, thetax, mean_du_dthetax))
        elif theta == '0.0' or theta == '1.5708':
            if abs(mean_du_dtheta) < 1e-4:
                mean_du_dtheta = 0.0
            else:
                print("Warning: du/dtheta for theta={} and thetax={} is {}.".format(theta, thetax, mean_du_dtheta))
        dus.append((theta, thetax, mean_du_dtheta, mean_du_dthetax))
        dus = sorted(dus, key=lambda x: (x[0], x[1]))
    # 2) output dus as to theta and thetax, both for files and arrays
    theta_list = []
    thetax_list = []
    theta_du_data_list = {} # element: theta: [(thetax, du/dthetax)]
    thetax_du_data_list = {} # element: thetax: [(theta, du/dtheta)]
    for du in dus:
        theta_du_data_file = 'theta-{}-du.data'.format(du[0])
        thetax_du_data_file = 'thetax-{}-du.data'.format(du[1])
        if du[0] not in theta_list:
            theta_du_data_list[du[0]] = [(float(du[1]), du[3])]
            theta_list.append(du[0])
            with open(theta_du_data_file, 'w') as tf:
                tf.write('{:.4f}  {:11.8f}\n'.format(float(du[1]), du[3]))
        else:
            theta_du_data_list[du[0]].append((float(du[1]), du[3]))
            with open(theta_du_data_file, 'a') as tf:
                tf.write('{:.4f}  {:11.8f}\n'.format(float(du[1]), du[3]))
        if du[1] not in thetax_list:
            thetax_du_data_list[du[1]] = [(float(du[0]), du[2])]
            thetax_list.append(du[1])
            with open(thetax_du_data_file, 'w') as tf:
                tf.write('{:.4f}  {:11.8f}\n'.format(float(du[0]), du[2]))
        else:
            thetax_du_data_list[du[1]].append((float(du[0]), du[2]))
            with open(thetax_du_data_file, 'a') as tf:
                tf.write('{:.4f}  {:11.8f}\n'.format(float(du[0]), du[2]))
    # 3) fit each element in theta_du_data_list and thetax_du_data_list
    errfunc_two_param = lambda p, x, y: fit_target_two_param(x, p) - y
    # 3.1) fit each A(theta) and B(theta) by du/dthetax = 2*A(theta)*sin(2*thetax)*(sin(thetax)^2-B(theta))
    A_theta = {} # element: {theta: A}
    B_theta = {} # element: {theta: B}
    for theta in theta_du_data_list:
        theta_du_fit_file = 'theta-{}-du.fit'.format(theta)
        thetax_list, du_dthetax_list = zip(*theta_du_data_list[theta])
        thetax_list = np.array(thetax_list)
        du_dthetax_list = np.array(du_dthetax_list)
        pfit, pcov, infodict, errmsg, success = leastsq(errfunc_two_param, (-10, 0.5), \
            args=(thetax_list, du_dthetax_list), full_output=1, epsfcn=0.000001)
        A_theta[theta] = pfit[0]
        B_theta[theta] = pfit[1]
        ssErr = (infodict['fvec']**2).sum()
        ssTot = ((du_dthetax_list-du_dthetax_list.mean())**2).sum()
        rsquared = 1-(ssErr/ssTot )
        with open(theta_du_fit_file, 'w') as tf:
            tf.write('Fitting with formula: du/dthetax = 2*A(theta)*sin(2*thetax)*(sin(thetax)^2-B(theta))\n')
            tf.write('Fitted results:\n')
            tf.write(' '*15 + 'A = {:.5f}\n'.format(pfit[0]))
            tf.write(' '*15 + 'B = {:.5f}\n'.format(pfit[1]))
            tf.write('Fitted errors:\n')
            tf.write(' '*11 + 'A_err = {:.5f}\n'.format(np.sqrt(pcov[0][0])))
            tf.write(' '*11 + 'B_err = {:.5f}\n'.format(np.sqrt(pcov[1][1])))
            tf.write('R squared: {:.6f}\n'.format(rsquared))
            tf.write('RMSE: {:.6f}\n'.format(np.sqrt(ssErr/len(thetax_list))))
        x_exp = np.linspace(min(thetax_list), max(thetax_list), 40)
        y_exp = fit_target_two_param(x_exp, pfit)
        plot(thetax_list, du_dthetax_list, x_exp, y_exp, rsquared, xlabel='thetax', \
            ylabel='du/dthetax', file_name='theta-{}-du'.format(theta), label='theta = {}'.format(theta))
    # 3.2) fit each A(thetax) and B(thetax) by du/dtheta = 2*A(thetax)*sin(2*theta)*(sin(theta)^2-B(thetax))
    A_thetax = {} # element: {thetax: A}
    B_thetax = {} # element: {thetax: B}
    for thetax in thetax_du_data_list:
        thetax_du_fit_file = 'thetax-{}-du.fit'.format(thetax)
        theta_list, du_dtheta_list = zip(*thetax_du_data_list[thetax])
        theta_list = np.array(theta_list)
        du_dtheta_list = np.array(du_dtheta_list)
        pfit, pcov, infodict, errmsg, success = leastsq(errfunc_two_param, (-10, 0.5), \
            args=(theta_list, du_dtheta_list), full_output=1, epsfcn=0.000001)
        A_thetax[thetax] = pfit[0]
        B_thetax[thetax] = pfit[1]
        ssErr = (infodict['fvec']**2).sum()
        ssTot = ((du_dtheta_list-du_dtheta_list.mean())**2).sum()
        rsquared = 1-(ssErr/ssTot )
        with open(thetax_du_fit_file, 'w') as tf:
            tf.write('Fitting with formula: du/dtheta = 2*A(thetax)*sin(2*theta)*(sin(theta)^2-B(thetax))\n')
            tf.write('Fitted results:\n')
            tf.write(' '*15 + 'A = {:.5f}\n'.format(pfit[0]))
            tf.write(' '*15 + 'B = {:.5f}\n'.format(pfit[1]))
            tf.write('Fitted errors:\n')
            tf.write(' '*11 + 'A_err = {:.5f}\n'.format(np.sqrt(pcov[0][0])))
            tf.write(' '*11 + 'B_err = {:.5f}\n'.format(np.sqrt(pcov[1][1])))
            tf.write('R squared: {:.6f}\n'.format(rsquared))
            tf.write('RMSE: {:.6f}\n'.format(np.sqrt(ssErr/len(theta_list))))
        x_exp = np.linspace(min(theta_list), max(theta_list), 40)
        y_exp = fit_target_two_param(x_exp, pfit)
        plot(theta_list, du_dtheta_list, x_exp, y_exp, rsquared, xlabel='theta', \
            ylabel='du/dtheta', file_name='thetax-{}-du'.format(thetax), label='thetax = {}'.format(thetax))
    # 3.3) write A, B as theta and thetax to files
    with open('A_B_of_theta.data', 'w') as tf:
        for theta in A_theta:
            tf.write('{} {:.6f} {:.6f}\n'.format(theta, A_theta[theta], B_theta[theta]))
    with open('A_B_of_thetax.data', 'w') as tf:
        for thetax in A_thetax:
            tf.write('{} {:.6f} {:.6f}\n'.format(thetax, A_thetax[thetax], B_thetax[thetax]))
    # 4) fit R1, R2, R3, (R4), R5, and R6 from A(theta), B(theta), A(thetax), and B(thetax)
    errfunc_three_param = lambda p, x, y: fit_target_three_param(x, p) - y
    # 4.1) fit R1, R2, and R3 from A(theta) = R1*sin(theta)^4+R2*sin(theta)^2+R3
    theta_list = np.array([float(key) for key in A_theta])
    A_theta_list = np.array([A_theta[key] for key in A_theta])
    pfit, pcov, infodict, errmsg, success = leastsq(errfunc_three_param, (-1, 10, -10), \
        args=(theta_list, A_theta_list), full_output=1, epsfcn=0.000001)
    R1 = pfit[0]
    R2 = pfit[1]
    R3 = pfit[2]
    ssErr = (infodict['fvec']**2).sum()
    ssTot = ((A_theta_list-A_theta_list.mean())**2).sum()
    rsquared = 1-(ssErr/ssTot )
    with open('A_of_theta.fit', 'w') as tf:
        tf.write('Fitting with formula: A(theta) = R1*sin(theta)^4+R2*sin(theta)^2+R3\n')
        tf.write('Fitted results:\n')
        tf.write(' '*15 + 'R1 = {:.5f}\n'.format(R1))
        tf.write(' '*15 + 'R2 = {:.5f}\n'.format(R2))
        tf.write(' '*15 + 'R3 = {:.5f}\n'.format(R3))
        tf.write('Fitted errors:\n')
        tf.write(' '*11 + 'R1_err = {:.5f}\n'.format(np.sqrt(pcov[0][0])))
        tf.write(' '*11 + 'R2_err = {:.5f}\n'.format(np.sqrt(pcov[1][1])))
        tf.write(' '*11 + 'R3_err = {:.5f}\n'.format(np.sqrt(pcov[2][2])))
        tf.write('R squared: {:.6f}\n'.format(rsquared))
        tf.write('RMSE: {:.6f}\n'.format(np.sqrt(ssErr/len(theta_list))))
    x_exp = np.linspace(min(theta_list), max(theta_list), 40)
    y_exp = fit_target_three_param(x_exp, pfit)
    label_r1r2r3 = 'R1 = {:.5f}\nR2 = {:.5f}\nR3 = {:.5f}\n'.format(R1, R2, R3)
    plot(theta_list, A_theta_list, x_exp, y_exp, rsquared, xlabel='theta', \
        ylabel='A(theta)', file_name='A_of_theta', label=label_r1r2r3)
    # 4.2) fit R4 from averaging B(theta)
    B_theta_list = np.array([B_theta[key] for key in B_theta])
    R4 = np.mean(B_theta_list)
    with open('B_of_theta.fit', 'w') as tf:
        tf.write('Fitting with formula: B(theta) = R4\n')
        tf.write('Fitted results:\n')
        tf.write(' '*15 + 'R4 = {:.5f}\n'.format(R4))
        tf.write('R squared: {:.6f}\n'.format(0.0))
        tf.write('RMSE: {:.6f}\n'.format(np.sqrt(((B_theta_list-R4)**2).sum()/len(B_theta_list))))
    y_exp = R4 * np.ones(len(x_exp))
    label_r4 = 'R4 = {:.5f}'.format(R4)
    plot(theta_list, B_theta_list, x_exp, y_exp, 0.0, xlabel='theta', \
        ylabel='B(theta)', file_name='B_of_theta', label=label_r4)
    # 4.3) fit R5 from A(thetax) = a0*sin(thetax)^4+a1*sin(thetax)^2+R5
    thetax_list = np.array([float(key) for key in A_thetax])
    A_thetax_list = np.array([A_thetax[key] for key in A_thetax])
    pfit, pcov, infodict, errmsg, success = leastsq(errfunc_three_param, (1, -1, -20), \
        args=(thetax_list, A_thetax_list), full_output=1, epsfcn=0.000001)
    R5 = pfit[2]
    ssErr = (infodict['fvec']**2).sum()
    ssTot = ((A_thetax_list-A_thetax_list.mean())**2).sum()
    rsquared = 1-(ssErr/ssTot )
    with open('A_of_thetax.fit', 'w') as tf:
        tf.write('Fitting with formula: A(thetax) = a0*sin(thetax)^4+a1*sin(thetax)^2+R5\n')
        tf.write('Fitted results:\n')
        tf.write(' '*15 + 'R5 = {:.5f}\n'.format(R5))
        tf.write('Fitted errors:\n')
        tf.write(' '*11 + 'R5_err = {:.5f}\n'.format(np.sqrt(pcov[2][2])))
        tf.write('R squared: {:.6f}\n'.format(rsquared))
        tf.write('RMSE: {:.6f}\n'.format(np.sqrt(ssErr/len(thetax_list))))
    x_exp = np.linspace(min(thetax_list), max(thetax_list), 40)
    y_exp = fit_target_three_param(x_exp, pfit)
    label_r5 = 'R5 = {:.5f}'.format(R5)
    plot(thetax_list, A_thetax_list, x_exp, y_exp, rsquared, xlabel='thetax', \
        ylabel='A(thetax)', file_name='A_of_thetax', label=label_r5)
    # 4.4) fit R6 from B(thetax) = a0*sin(thetax)^4+a1*sin(thetax)^2+R6
    thetax_list = np.array([float(key) for key in B_thetax])
    B_thetax_list = np.array([B_thetax[key] for key in B_thetax])
    pfit, pcov, infodict, errmsg, success = leastsq(errfunc_three_param, (1, -1, -20), \
        args=(thetax_list, B_thetax_list), full_output=1, epsfcn=0.000001)
    R6 = pfit[2]
    ssErr = (infodict['fvec']**2).sum()
    ssTot = ((B_thetax_list-B_thetax_list.mean())**2).sum()
    rsquared = 1-(ssErr/ssTot )
    with open('B_of_thetax.fit', 'w') as tf:
        tf.write('Fitting with formula: B(thetax) = a0*sin(thetax)^4+a1*sin(thetax)^2+R6\n')
        tf.write('Fitted results:\n')
        tf.write(' '*15 + 'R6 = {:.5f}\n'.format(R6))
        tf.write('Fitted errors:\n')
        tf.write(' '*11 + 'R6_err = {:.5f}\n'.format(np.sqrt(pcov[2][2])))
        tf.write('R squared: {:.6f}\n'.format(rsquared))
        tf.write('RMSE: {:.6f}\n'.format(np.sqrt(ssErr/len(thetax_list))))
    x_exp = np.linspace(min(thetax_list), max(thetax_list), 40)
    y_exp = fit_target_three_param(x_exp, pfit)
    label_r6 = 'R6 = {:.5f}'.format(R6)
    plot(thetax_list, B_thetax_list, x_exp, y_exp, rsquared, xlabel='thetax', \
        ylabel='B(thetax)', file_name='B_of_thetax', label=label_r6)
    # 4.5) write R1, R2, R3, R4, R5, R6 to a file, but replace R4 value with 0.5
    R4 = 0.5  # This value is fixed to 0.5 to comply with real physics
    with open('cphmd.parm', 'w') as tf:
        tf.write('R1\t{:.6f}\n'.format(R1))
        tf.write('R2\t{:.6f}\n'.format(R2))
        tf.write('R3\t{:.6f}\n'.format(R3))
        tf.write('R4\t{:.6f}\n'.format(R4))
        tf.write('R5\t{:.6f}\n'.format(R5))
        tf.write('R6\t{:.6f}\n\n'.format(R6))
        tf.write('Copy and paste the following line to the corresponding Asp/Glu line in a CpHMD parm file:\n')
        tf.write('{:.6f},{:.6f},{:.6f},{:.6f},{:.6f},{:.6f},\n'.format(R1,R2,R3,R4,R5,R6))

def fit_target_two_param(x, p):
    # du/dx = 2*A*sin(2*x)*(sin(x)^2-B)
    return 2 * p[0] * np.sin(2*x) * (np.sin(x)**2 - p[1])

def fit_target_three_param(x, p):
    # du/dx = a0*sin(x)^4+a1*sin(x)^2+a2
    return p[0] * (np.sin(x))**4.0 + p[1] * np.sin(x)**2 + p[2]

def plot(x_obs, y_obs, x_exp, y_exp, r2, xlabel='x', ylabel='y', file_name='fit', label='data'):
    _ = plt.figure(figsize=(3.5,3.5))
    plt.scatter(x_obs, y_obs, marker='x', label=label)
    plt.plot(x_exp, y_exp, color='r', label='R^2: {:.5f}'.format(r2))
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.legend()
    plt.tight_layout()
    plt.savefig(file_name + '.png', bbox_inches='tight', transparent=False)

if __name__ == '__main__':
    label = 'prod'
    fit_type = 'single'
    begin = 0
    end = -1
    if len(sys.argv) > 3:
        begin = int(sys.argv[3])
    if len(sys.argv) > 4:
        end = int(sys.argv[4])
    if len(sys.argv) > 1:
        label = sys.argv[1]
        if label == '-h':
            print("Usage: cphmd_parm_fit.py [label (default: prod)] [fit_type (default: single)] [begin (default: 0)] [end (default: -1)]")
            exit
    if len(sys.argv) > 2:
        fit_type = sys.argv[2]
        if fit_type == 'single':
            fit_single(label, begin=begin, end=end)
        elif fit_type == 'double':
            fit_double(label, begin=begin, end=end)
        elif fit_type == 'his':
            fit_his(label, begin=begin, end=end)
        else:
            raise Exception("InputError: fit_type must be one of 'single', 'double', 'his'")
