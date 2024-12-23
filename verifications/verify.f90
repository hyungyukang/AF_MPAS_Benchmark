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
      retval = nf90_open('verif_HPC11_GNU_VR20km-4km_N05_D500_theta_f06h.nc', nf90_nowrite, ncid)
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

      n = nt

      sum1 = 0.d0
      sum2 = 0.d0
      do k = 1,nlev
         do i = 1,nCells
            sum1 = (theta_test(k,i,n)-theta_ref(k,i,1))**2.0
            sum2 = (                  theta_ref(k,i,1))**2.0
         end do
      end do

      l2_error_norm = dsqrt(sum1/sum2)

      print*, 'L2 error norm (Test vs Ref) of theta at 06 h =', l2_error_norm

end program read_theta

