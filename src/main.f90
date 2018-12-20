program main
    implicit none
    
    ! raw data information
    integer :: xdim  ! x-dimension of raw array
    integer :: ydim  ! y-dimension of raw array
    integer :: zdim  ! z-dimension of raw array
    integer :: xdelta ! number of points in each tile
    integer :: ydelta ! number of points in each tile
    real    :: known_lat ! the lat of bottom-left point
    real    :: known_lon ! the lon of bottom-left point 
    real    :: dx ! the delta x in deg 
    real    :: dy ! the delta y in deg 

    integer :: signed   ! 0=unsigned data, 1=signed data 
    integer :: endian   ! 0=big endian, 1=little endian
    integer :: urban    ! the id of urban
    integer :: wordsize ! number of bytes to use for each array element
    real    :: scale    ! value to multiply array elements by before truncation to integers

    ! new data 
    integer :: newnx   ! x-dimension of raw array
    integer :: newny   ! y-dimension of raw array    
    
    ! raw data 
    real,allocatable,dimension(:) :: lats ! lats of raw data
    real,allocatable,dimension(:) :: lons ! lons of raw data
    real,allocatable,dimension(:,:,:) :: modis ! raw data
    
    real,allocatable,dimension(:,:) :: newlats ! lats of raw data
    real,allocatable,dimension(:,:) :: newlons ! lons of raw data
    real,allocatable,dimension(:,:) :: newdata ! raw data
    
    ! landindex 
    integer :: oldindex = 13
    integer :: newindex = 13

    ! file
    character(len=200) :: oldfile
    character(len=200) :: newfile
    character(len=200) :: outfile

    character(len=128) :: oldpath
    character(len=128) :: newpath    
    character(len=128) :: outpath

    ! local
    integer :: i,j,k
    integer :: status, strlen
    real    :: xleft, yleft    
    real    :: maxlat,maxlon,minlat,minlon
    integer :: xstart, xend, ystart, yend
    character(len=23) :: fname
    ! function
    character(len=5),external :: integerToCharacter
    integer, external :: system

    ! Declare the local variables
    integer                      :: fnamelen    ! The len of the name of input file. 
    integer                      :: ierror      ! Flag for open file error 
    integer                      :: inputunit=9 ! Open unit 
    character(len=100)           :: inputname   ! The name of input file 
    character(len=200)           :: errmsg      ! error message

    namelist /description/ xdim, ydim, zdim, xdelta, ydelta, known_lat, known_lon, &
                    dx, dy, signed, endian, urban, wordsize, scale, newnx, newny, &
                    oldindex, newindex

    namelist /path/ oldpath, newfile, outpath

 ! write(*,*) "=========================================================="
 ! write(*,*) "          Copyright (C) 2018, Linhong Xiao"
 ! write(*,*) "         updateLanduse version 2.0.1 2018.05.02         "
 ! write(*,*) "=========================================================="

 !  read the input file name
 if (command_argument_count() == 0) then
     write(*,*) '-------------------parameter file name--------------------'
     write(*,*) 'Notice: The input file used is input.up in local folder. '
     write(*,*) '----------------------------------------------------------'
     write(*,*) '                                                             '
     inputname = 'input.up'
 elseif (command_argument_count() > 0) then
     call get_command_argument(1,inputname,fnamelen,ierror)
     ! write(*,*) fnamelen
     if (fnamelen < 100) then
        write(*,*) '-------------------parameter file name--------------------'
        write(*,*) 'Notice: The input file used is ' // trim(inputname)
        write(*,*) '----------------------------------------------------------'
        write(*,*) '                                                          '
     else
        write(*,*) '****************************************************'
        write(*,*) '*** Error: The name of input file is too LONG!   ***'
        write(*,*) '*** The length of the input name is:',fnamelen, '***'
        write(*,*) '*** Please keep the LEN less than 100 !          ***'
        write(*,*) '****************************************************'
        stop
     end if
 end if

 ! open input file and deteminte if exists
  open(inputunit,file=inputname,form='formatted',iostat=ierror,status='old',iomsg=errmsg)
  if(ierror /= 0)then
      write(*,*) errmsg
      write(*,*) inputname
      stop 
  end if  

  read(inputunit,NML=description,iostat=ierror,iomsg=errmsg )
   if(ierror/=0) write(*,*) errmsg
   if(ierror/=0) stop

  read(inputunit,NML=path,iostat=ierror,iomsg=errmsg )
   if(ierror/=0) write(*,*) errmsg
   if(ierror/=0) stop
  close(inputunit)
 

    allocate( lats(ydelta),lons(xdelta),modis(xdelta, ydelta, zdim) )
    allocate( newlats(newnx, newny),newlons(newnx, newny),newdata(newnx, newny) )
    call readnew(newfile, newnx, newny, newlats, newlons, newdata)

    ! handle the core operations
    do i=1,xdim/xdelta 
        xleft=known_lon+(i-1)*xdelta*dx
        call createlist(xleft, dx, xdelta, lons)

        do j=1,ydim/ydelta
           yleft=known_lat+(j-1)*ydelta*dy 
           call createlist(yleft, dy, ydelta, lats)

           xstart = (i-1)*xdelta+1
           xend   = i*xdelta
           ystart = (j-1)*ydelta+1
           yend   = j*ydelta
           fname  = integerToCharacter(xstart)//"-"//integerToCharacter(xend)// &
                    "."//integerToCharacter(ystart)//"-"//integerToCharacter(yend)
           ! read the raw data
           write(*,*) fname
           oldfile = trim(oldpath)//"/"//trim(fname)
           call countLen(oldfile,strlen)
           call read_geogrid(oldfile, strlen, modis, xdelta, ydelta, zdim,&
                              signed, endian, scale, wordsize, status)
                ! char * fname,        /* The name of the file to read from */
                ! int * len,           /* The length of the filename */
                ! float * rarray,      /* The array to be filled */
                ! int * nx,            /* x-dimension of the array */
                ! int * ny,            /* y-dimension of the array */
                ! int * nz,            /* z-dimension of the array */
                ! int * isigned,       /* 0=unsigned data, 1=signed data */
                ! int * endian,        /* 0=big endian, 1=little endian */
                ! float * scalefactor, /* value to multiply array elements by before truncation to integers */
                ! int * wordsize,      /* number of bytes to use for each array element */
                ! int * status)
           !write(*,"(F10.2)") maxval(modis) 
           !stop           
           ! do some change
           call match(xdelta, ydelta, lons, lats, modis, newnx, newny, newlons, newlats, newdata, oldindex, newindex)

           ! output the new 
           outfile = trim(outpath)//"/"//trim(fname)
           !write(*,*) outfile
           status = system( "mkdir -p "// outpath )
           call countLen(outfile,strlen)    
           call write_geogrid(modis, xdelta, ydelta, zdim, signed, endian, scale, wordsize, outfile, strlen)
           !stop
        end do 
    end do 
    status = system( "cp "//trim(oldpath)//"/index"//" "//outpath )
end program

!=====================================================================================!

character(len=*) function integerToCharacter(ii)
  ! usage: 
    ! character(len=5),external :: integerToCharacter
    ! write(*,*) integerToCharacter(2)  
    implicit none
    integer, intent(in) :: ii
    write(integerToCharacter,"(I5.5)") ii 

end function integerToCharacter

subroutine countLen(string, strlen)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
! Name: countLen
!
! Purpose: This routine receives a fortran string, and returns the number of 
!    characters in the string before the first "space" is encountered. It 
!    considers ascii characters 33 to 126 to be valid characters, and ascii 
!    0 to 32, and 127 to be "space" characters.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 

   implicit none

   ! Arguments
   character (len=*), intent(in) :: string
   integer, intent(out) :: strlen

   ! Local variables
   integer :: i, len_str, aval
   logical :: space

   space = .false.
   i = 1
   len_str = len(string)
   strlen = len_str
   do while ((i .le. len_str) .and. (.not. space))
      aval = ichar(string(i:i))
      if ((aval .lt. 33) .or. (aval .gt. 126)) then
         strlen = i - 1
         space = .true.
      end if
      i = i + 1
   end do
end subroutine countLen


subroutine createlist(start, delta, num, array)
  implicit none
  ! parameter
  real, intent(in)    :: start
  real, intent(in)    :: delta
  integer, intent(in) :: num
  real, intent(out) ,dimension(num) :: array

  ! local
  integer :: i 
  do i =1, num
    array(i) = start + (i-1)*delta
  end do   

end subroutine createlist


subroutine readnew(fname, nx, ny, lats, lons, array)
  implicit none
  ! calling
  character(len=*),intent(in) :: fname
  integer, intent(in)         :: nx
  integer, intent(in)         :: ny
  real, intent(out) ,dimension(nx, ny) :: lats
  real, intent(out) ,dimension(nx, ny) :: lons
  real, intent(out) ,dimension(nx, ny) :: array

  ! local
  character(200)    :: errormg ! the message of fail opening   
  integer           :: ierror  ! Flag for allocate 
  open(100,file=fname, form='unformatted', iostat=ierror, iomsg=errormg)
       read(100) lats
       read(100) lons
       read(100) array
  ! Check if writing data is successfule. 
  if(ierror /= 0) then
    write(*,*) errormg
    stop
  end if
  close(100)
end subroutine readnew

subroutine match(nx, ny, lons, lats, modis, newnx, newny, newlons, newlats, newdata, oldindex, newindex)

  implicit none
  ! calling
  integer, intent(in)   :: nx
  integer, intent(in)   :: ny
  real, intent(in) ,dimension(nx) :: lons
  real, intent(in) ,dimension(ny) :: lats  
  real, intent(inout) ,dimension(nx,ny) :: modis

  integer, intent(in)   :: newnx
  integer, intent(in)   :: newny
  real, intent(in) ,dimension(newnx, newny) :: newlons
  real, intent(in) ,dimension(newnx, newny) :: newlats  
  real, intent(in) ,dimension(newnx, newny) :: newdata

  integer, intent(in) :: oldindex
  integer, intent(in) :: newindex

  ! local
  integer :: i,j 
  integer :: ix
  integer :: iy  

  do i=1,newnx
    do j=1,newny
        if ( newlons(i,j)>lons(1) .and. newlons(i,j)<lons(nx) .and. &
             newlats(i,j)>lats(1) .and. newlats(i,j)<lats(ny) ) then
        if ( int(newdata(i,j)) ==  newindex) then
           call ind(nx, ny, lons, lats, newlons(i,j), newlats(i,j), ix, iy)
           if (ix /=0 .and. iy /=0) then
               modis(ix,iy) = oldindex
           end if     
        end if    
        end if 
    end do 
  end do       

end subroutine match

subroutine ind(nx, ny, lons, lats, lon, lat, ix, iy)
  implicit none
  ! calling
  integer, intent(in)   :: nx
  integer, intent(in)   :: ny
  real, intent(in), dimension(nx) :: lons
  real, intent(in), dimension(ny) :: lats  

  real, intent(in)  ::  lon
  real, intent(in)  ::  lat

  integer, intent(out) :: ix
  integer, intent(out) :: iy

  ! local
   integer :: i 

   ix=0
   iy=0  
   do i=1,nx-1
      if ( lons(i)<= lon .and. lons(i+1)> lon  ) then
        ix=i
        exit 
      end if   
   end do  

   do i=1,ny-1
      if ( lats(i)<= lat .and. lats(i+1)> lat  ) then
        iy=i
        exit 
      end if   
   end do 
end subroutine  ind
