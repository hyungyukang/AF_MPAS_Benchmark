!=================================================================================
! A fortran program to verify the correctness of the simulations
!
! - Reference data : Theta at 48 hours simulated on HPC11 with the GNU compiler
!
! Note: The numerical results may vary depending on the system architecture and
!       compiler. To ensure baseline accuracy, a verification dataset
!       'verif_HPC11_GNU_VR20km-4km_N01_D700_theta_f48h.nc' is provided to compare
!       the model outputs of the target machine with those obtained on
!       the Air Force HPC11 system. The verification process computes the
!       L2 error norm of the three-dimensional potential temperature after
!       48 forecast hours. The acceptable error threshold is < 1.0E-2.
!=================================================================================

program read_theta
      use netcdf
      implicit none

      ! NetCDF file and variable identifiers
      integer :: timeID, nCellsID, levID
      integer :: ncid, varid, retval, close
      integer :: nt,nCells,nlev
      integer :: i,k,n
      real(kind=8) :: sum1,sum2,l2_error_norm

      ! 3D variable array
      real(kind=8), dimension(:,:,:), allocatable :: theta_ref,theta_test

      !------------------------------------------------------
      ! Reading reference -----------------------------------
      !------------------------------------------------------

      ! Open the NetCDF file
      retval = nf90_open('verif_HPC11_GNU_VR20km-4km_N01_D700_theta_f48h.nc', nf90_nowrite, ncid)
      if (retval /= nf90_noerr) then
          print *, 'Error: unable to open file.'
          stop
      end if

      ! Get the variable ID for 'theta'
      retval = nf90_inq_varid(ncid, 'theta', varid)
      if (retval /= nf90_noerr) then
          print *, 'Error: unable to find variable theta.'
          close = nf90_close(ncid)
          stop
      end if

      retval = nf90_inq_dimid(ncid, 'Time', timeID)
      retval = nf90_inq_dimid(ncid, 'nCells', nCellsID)
      retval = nf90_inq_dimid(ncid, 'nVertLevels', levID)

      retval = nf90_inquire_dimension(ncid, timeID, len=nt)
      retval = nf90_inquire_dimension(ncid, nCellsID, len=nCells)
      retval = nf90_inquire_dimension(ncid, levID, len=nlev)

      allocate(theta_ref(nlev,nCells,nt))

      ! Read the 'theta' variable
      retval = nf90_get_var(ncid, varid, theta_ref)
      if (retval /= nf90_noerr) then
          print *, 'Error: unable to read variable theta.'
          close = nf90_close(ncid)
          stop
      end if

      ! Close the NetCDF file
      retval = nf90_close(ncid)
      if (retval /= nf90_noerr) then
          print *, 'Error: unable to close file.'
          stop
      end if


      !------------------------------------------------------
      ! Reading test ----------------------------------------
      !------------------------------------------------------

      ! Open the NetCDF file
      retval = nf90_open('history.2021-08-27_00.00.00.nc', nf90_nowrite, ncid)
      if (retval /= nf90_noerr) then
          print *, 'Error: unable to open file.'
          stop
      end if

      ! Get the variable ID for 'theta'
      retval = nf90_inq_varid(ncid, 'theta', varid)
      if (retval /= nf90_noerr) then
          print *, 'Error: unable to find variable theta.'
          close = nf90_close(ncid)
          stop
      end if

      retval = nf90_inq_dimid(ncid, 'Time', timeID)
      retval = nf90_inq_dimid(ncid, 'nCells', nCellsID)
      retval = nf90_inq_dimid(ncid, 'nVertLevels', levID)

      retval = nf90_inquire_dimension(ncid, timeID, len=nt)
      retval = nf90_inquire_dimension(ncid, nCellsID, len=nCells)
      retval = nf90_inquire_dimension(ncid, levID, len=nlev)

      allocate(theta_test(nlev,nCells,nt))

      ! Read the 'theta' variable
      retval = nf90_get_var(ncid, varid, theta_test)
      if (retval /= nf90_noerr) then
          print *, 'Error: unable to read variable theta.'
          close = nf90_close(ncid)
          stop
      end if

      ! Close the NetCDF file
      retval = nf90_close(ncid)
      if (retval /= nf90_noerr) then
          print *, 'Error: unable to close file.'
          stop
      end if


      !------------------------------------------------------
      ! Computing L2 error norm at the last prediction time -
      !------------------------------------------------------

      n = nt ! Last time frame. Here nt equals 2.

      sum1 = 0.d0
      sum2 = 0.d0
      do k = 1,nlev
         do i = 1,nCells
            sum1 = (theta_test(k,i,n)-theta_ref(k,i,1))**2.0
            sum2 = (                  theta_ref(k,i,1))**2.0
         end do
      end do

      l2_error_norm = dsqrt(sum1/sum2)

      print*, 'L2 error norm (Test vs Ref) of theta at 48 h =', l2_error_norm

end program read_theta

