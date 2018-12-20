# updatelanduse

部分更新WRF静态数据中的土地利用数据


## 转化工具

### nc2bin

**安装**
bash install.sh

**使用**

``` bash
nc2bin MCD12Q1.nc asia_landuse.dat 19200 12000
```

输入的netcdf格式
> netcdf MCD12Q1 {
> dimensions:
>     y = 12000 ;
>     x = 19200 ;
> variables:
>     float lats(y, x) ;
>         lats:_FillValue = -999.f ;
>     float lons(y, x) ;
>         lons:_FillValue = -999.f ;
>     float landuse(y, x) ;
>         landuse:_FillValue = -999.f ;
>         landuse:coordinates = "lons lats" ;

输出
``` fortran
open(100,file=trim(fname), form='unformatted', iostat=ierror, iomsg=errormg)
     write(100) lats
     write(100) lons
     write(100) array
```

## 更新工具

**安装**
bash install.sh

**配置**

``` bash
vim input.up
```

``` 
&description
  xdim   = 43200         ! x-dimension of raw array
  ydim   = 21600         ! y-dimension of raw array
  zdim   = 1             ! z-dimension of raw array
  xdelta = 1200          ! number of points in each tile
  ydelta = 1200          ! number of points in each tile
  known_lat = -89.99583  ! the lat of bottom-left point
  known_lon = -179.99583 ! the lon of bottom-left point
  dx        = 0.00833333 ! the delta x in deg
  dy        = 0.00833333 ! the delta y in deg
  signed    = 0          ! 0=unsigned data, 1=signed data
  endian    = 0          ! 0=big endian, 1=little endian
  urban     = 13         ! the id of urban
  wordsize = 1           ! number of bytes to use for each array element
  scale    = 1.0         ! value to multiply array elements by before truncation to integers
  newnx    = 19200       ! x-dimension of new array
  newny    = 12000       ! y-dimension of new array
  oldindex = 13          ! index of landuse that will be change in raw data
  newindex = 13          ! index of landuse that will be change in new data
/

&path
  oldpath = "PATH/geog/modis_landuse_20class_30s_with_lakes", !原始的静态数据路径
  newfile = "PATH/asia_landuse.dat", ! 新的土里利用数据
  outpath = "./out", ！输出路径
/
```

**使用**
``` bash
updatelanduse input.up
```

运行完成后，可将out文件替代modis_landuse_20class_30s_with_lakes文件

**注意**

读入的文件格式必须是fortran的无格式文件，安装下面的接口函数转换

``` fortran
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
```