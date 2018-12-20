program main
  use netcdf
  implicit none 

  ! new data 
  character(len=200) :: iname, oname
  character(len=10)  :: strnx, strny 

  integer :: newnx   ! x-dimension of raw array
  integer :: newny   ! y-dimension of raw array 
  
  integer :: nlen, ierror

  real,allocatable,dimension(:,:) :: newlats ! lats of raw data
  real,allocatable,dimension(:,:) :: newlons ! lons of raw data
  real,allocatable,dimension(:,:) :: newdata ! raw data
 
  integer :: ncid, varid
  ! newnx = 19200
  ! newny = 12000

  if (command_argument_count() /= 4) then
     write(*,*) ' Convert NetCDF to Binary'
     write(*,*) ' Usage: convert iname oname nx ny '
     stop
  end if

  call get_command_argument(1, iname, nlen, ierror)
  call get_command_argument(2, oname, nlen, ierror)
  call get_command_argument(3, strnx, nlen, ierror)
  call get_command_argument(4, strny, nlen, ierror)

  read(strnx, '(I10)') newnx
  read(strny, '(I10)') newny

  allocate(newlats(newnx, newny), newlons(newnx, newny), newdata(newnx, newny))

  ! Open the file. NF90_NOWRITE tells netCDF we want read-only access to
  ! the file.
  call check( nf90_open(trim(iname), NF90_NOWRITE, ncid) )

  ! Get the varid of the data variable, based on its name.
  call check( nf90_inq_varid(ncid, "lats", varid) )

  ! Read the data.
  call check( nf90_get_var(ncid, varid, newlats) )

  ! Get the varid of the data variable, based on its name.
  call check( nf90_inq_varid(ncid, "lons", varid) )

  ! Read the data.
  call check( nf90_get_var(ncid, varid, newlons) )

  ! Get the varid of the data variable, based on its name.
  call check( nf90_inq_varid(ncid, "landuse", varid) )
  ! Read the data.

  call check( nf90_get_var(ncid, varid, newdata) )

  call check( nf90_close(ncid) )

  call writenew(oname, newnx, newny, transpose(newlats), transpose(newlons), transpose(newdata))

end program main

subroutine writenew(fname, nx, ny, lats, lons, array)
  implicit none
  ! calling
  character(len=*),intent(in) :: fname
  integer, intent(in)         :: nx
  integer, intent(in)         :: ny
  real, intent(in) ,dimension(nx, ny) :: lats
  real, intent(in) ,dimension(nx, ny) :: lons
  real, intent(in) ,dimension(nx, ny) :: array

  ! local
  character(200)    :: errormg ! the message of fail opening   
  integer           :: ierror  ! Flag for allocate 

  open(100,file=trim(fname), form='unformatted', iostat=ierror, iomsg=errormg)
       write(100) lats
       write(100) lons
       write(100) array
  ! Check if writing data is successfule. 
  if(ierror /= 0) then
    write(*,*) errormg
    stop
  end if
  close(100)
end subroutine writenew

subroutine check(status)
  use netcdf
  integer, intent ( in) :: status
  if(status /= nf90_noerr) then 
    write(*,*), trim(nf90_strerror(status))
    write(*,*) "error"
    stop 2
  end if
end subroutine check 
