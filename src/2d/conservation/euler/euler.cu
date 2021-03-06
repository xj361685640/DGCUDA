#include "../main.cu"

/* euler.cu
 *
 * This file contains the relevant information for making a system to solve
 *
 * d_t [   rho   ] + d_x [     rho * u    ] + d_y [    rho * v     ] = 0
 * d_t [ rho * u ] + d_x [ rho * u^2 + p  ] + d_y [   rho * u * v  ] = 0
 * d_t [ rho * v ] + d_x [  rho * u * v   ] + d_y [  rho * v^2 + p ] = 0
 * d_t [    E    ] + d_x [ u * ( E +  p ) ] + d_y [ v * ( E +  p ) ] = 0
 *
 */

__device__ double get_GAMMA();

__device__ void U0(double *, double, double);

__device__ void U_inflow(double *, double, double, double);

__device__ void U_outflow(double *, double, double, double);

/* size of the system */
int local_N = 4;

/***********************
 *
 * EULER DEVICE FUNCTIONS
 *
 ***********************/

__device__ void evalU0(double *U, double *V, int i) {
    int j;
    double u0[4];
    double X[2];

    U[0] = 0.;
    U[1] = 0.;
    U[2] = 0.;
    U[3] = 0.;

    for (j = 0; j < n_quad; j++) {

        // get the 2d point on the mesh
        get_coordinates_2d(X, V, j);

        // evaluate U0 here
        U0(u0, X[0], X[1]);

        // evaluate U at the integration point
        U[0] += w[j] * u0[0] * basis[i * n_quad + j];
        U[1] += w[j] * u0[1] * basis[i * n_quad + j];
        U[2] += w[j] * u0[2] * basis[i * n_quad + j];
        U[3] += w[j] * u0[3] * basis[i * n_quad + j];
    }
}

/* evaluate pressure
 *
 * evaluates the pressure for U
 */
__device__ double pressure(double *U) {

    double rho, rhou, rhov, E;
    rho  = U[0];
    rhou = U[1];
    rhov = U[2];
    E    = U[3];
    
    return (get_GAMMA() - 1.) * (E - (rhou*rhou + rhov*rhov) / 2. / rho);
}

/* is physical
 *
 * returns true if the density and pressure at U make physical sense
 */
__device__ bool is_physical(double *U) {
    if (U[0] < 0) {
        return false;
    }

    if (pressure(U) < 0) {
        return false;
    }

    return true;
}

/* check physical
 *
 * if U isn't physical, replace the solution with the constant average value
 */
__device__ void check_physical(double *C_global, double *C, double *U, int idx) {
    int i;

    // check to see if U is physical
    if (!is_physical(U)) {
        // set C[1] to C[n_p] to zero
        for (i = 1; i < n_p; i++) {
            C_global[num_elem * n_p * 0 + i * num_elem + idx] = 0.;
            C_global[num_elem * n_p * 1 + i * num_elem + idx] = 0.;
            C_global[num_elem * n_p * 2 + i * num_elem + idx] = 0.;
            C_global[num_elem * n_p * 3 + i * num_elem + idx] = 0.;

            C[n_p * 0 + i] = 0.;
            C[n_p * 1 + i] = 0.;
            C[n_p * 2 + i] = 0.;
            C[n_p * 3 + i] = 0.;
        }

        // rebuild the solution as simply the average value
        U[0] = C[n_p * 0 + 0] * basis[0];
        U[1] = C[n_p * 1 + 0] * basis[0];
        U[2] = C[n_p * 2 + 0] * basis[0];
        U[3] = C[n_p * 3 + 0] * basis[0];
    }
}

/* evaluate c
 *
 * evaulates the speed of sound c
 */
__device__ double eval_c(double *U) {
    double p = pressure(U);
    double rho = U[0];

    return sqrt(get_GAMMA() * p / rho);
}    

/***********************
 *
 * EULER FLUX
 *
 ***********************/
/* takes the actual values of rho, u, v, and E and returns the flux 
 * x and y components. 
 * NOTE: this needs the ACTUAL values for u and v, NOT rho * u, rho * v.
 */
__device__ void eval_flux(double *U, double *flux_x, double *flux_y,
                          double *V, double t, int j, int left_side) {

    // evaluate pressure
    double rho, rhou, rhov, E;
    double p = pressure(U);
    rho  = U[0];
    rhou = U[1];
    rhov = U[2];
    E    = U[3];

    // flux_x 
    flux_x[0] = rhou;
    flux_x[1] = rhou * rhou / rho + p;
    flux_x[2] = rhou * rhov / rho;
    flux_x[3] = rhou * (E + p) / rho;

    // flux_y
    flux_y[0] = rhov;
    flux_y[1] = rhou * rhov / rho;
    flux_y[2] = rhov * rhov / rho + p;
    flux_y[3] = rhov * (E + p) / rho;
}

/***********************
 *
 * RIEMAN SOLVER
 *
 ***********************/
/* finds the max absolute value of the jacobian for F(u).
 *  |u - c|, |u|, |u + c|
 */
__device__ double eval_lambda(double *U_left, double *U_right,
                              double *V,      double t,
                              double nx,      double ny,
                              int j, int left_side) {
                              
    double s_left, s_right;
    double c_left, c_right;
    double u_left, v_left;
    double u_right, v_right;
    double left_max, right_max;

    // get c for both sides
    c_left  = eval_c(U_left);
    c_right = eval_c(U_right);

    // find the speeds on each side
    u_left  = U_left[1] / U_left[0];
    v_left  = U_left[2] / U_left[0];
    u_right = U_right[1] / U_right[0];
    v_right = U_right[2] / U_right[0];
    s_left  = nx * u_left  + ny * v_left;
    s_right = nx * u_right + ny * v_right; 
    
    // if speed is positive, want s + c, else s - c
    if (s_left > 0.) {
        left_max = s_left + c_left;
    } else {
        left_max = -s_left + c_left;
    }

    // if speed is positive, want s + c, else s - c
    if (s_right > 0.) {
        right_max = s_right + c_right;
    } else {
        right_max = -s_right + c_right;
    }

    // return the max absolute value of | s +- c |
    if (abs(left_max) > abs(right_max)) {
        return abs(left_max);
    } else { 
        return abs(right_max);
    }
}

/* local lax-friedrichs riemann solver
 */
__device__ void riemann_solver(double *F_n, double *U_left, double *U_right,
                               double *V, double t,
                               double nx, double ny,
                               int j, int left_side) {
    int n;

    double flux_x_l[4], flux_x_r[4];
    double flux_y_l[4], flux_y_r[4];

    // calculate the left and right fluxes
    eval_flux(U_left, flux_x_l, flux_y_l, V, t, j, left_side);
    eval_flux(U_right, flux_x_r, flux_y_r, V, t, j, left_side);

    double lambda = eval_lambda(U_left, U_right, V, t, nx, ny, j, left_side);

    // calculate the riemann problem at this integration point
    for (n = 0; n < N; n++) {
        F_n[n] = 0.5 * ((flux_x_l[n] + flux_x_r[n]) * nx + (flux_y_l[n] + flux_y_r[n]) * ny 
                    + lambda * (U_left[n] - U_right[n]));
    }
}

/***********************
 *
 * CFL CONDITION
 *
 ***********************/
/* global lambda evaluation
 *
 * computes the max eigenvalue of |u + c|, |u|, |u - c|.
 */
__global__ void eval_global_lambda(double *C, double *lambda, 
                                   double *V1x, double *V1y,
                                   double *V2x, double *V2y,
                                   double *V3x, double *V3y,
                                   double t) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < num_elem) { 
        double c, s;

        double U[4];
        // get cell averages
        U[0] = C[num_elem * n_p * 0 + idx] * basis[0];
        U[1] = C[num_elem * n_p * 1 + idx] * basis[0];
        U[2] = C[num_elem * n_p * 2 + idx] * basis[0];
        U[3] = C[num_elem * n_p * 3 + idx] * basis[0];

        // evaluate c
        c = eval_c(U);

        // speed of the wave
        s = sqrt(U[1]*U[1] + U[2]*U[2])/U[0];

        // return the max eigenvalue
        if (s > 0) {
            lambda[idx] = s + c;
        } else {
            lambda[idx] = -s + c;
        }
    }
}

/*
 * source term
 */
__device__ void source_term(double *S, double *U, double *V, double t, int j) {
    int n;
    for (n = 0; n < N; n++) {
        S[n] = 0;
    }
}

/* evaluate pressure
 * 
 * evaluates pressure at the three vertex points for output
 * THREADS: num_elem
 */
__global__ void eval_pressure(double *C, double *Uv1, double *Uv2, double *Uv3) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < num_elem) {
        int i, n;
        double U1[4], U2[4], U3[4];

        // calculate values at the integration points
        for (n = 0; n < N; n++) {
            U1[n] = 0.;
            U2[n] = 0.;
            U3[n] = 0.;
            for (i = 0; i < n_p; i++) {
                U1[n] += C[num_elem * n_p * n + i * num_elem + idx] * basis_vertex[i * 3 + 0];
                U3[n] += C[num_elem * n_p * n + i * num_elem + idx] * basis_vertex[i * 3 + 1];
                U2[n] += C[num_elem * n_p * n + i * num_elem + idx] * basis_vertex[i * 3 + 2];
            }
        }

        // store result
        Uv1[idx] = pressure(U1);
        Uv2[idx] = pressure(U2);
        Uv3[idx] = pressure(U3);
    }
}


