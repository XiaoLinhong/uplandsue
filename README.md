# 土地利用更新工具

部分更新WRF静态数据中的土地利用数据。


## 转化工具

### nc2bin
该工具可将NetCDF格式的土地利用数据转化为fortran的无格式二进制数据，便于土地利用更新工具读取。

**安装**
该工具存放在HOME/utile目录中；安装时需要修改HOME/utile/install.sh中NetCDF库的位置。

修改完成后，执行
``` bash
bash install.sh
```

**使用**

使用时，执行
``` bash
nc2bin MCD12Q1.nc asia_landuse.dat 19200 12000
```
其中，

1. MCD12Q1.nc为存放土里利用类型的NC格式数据；
2. asia_landuse.dat 为输出数据；
3. 19200 12000：为网格信息；

MCD12Q1.nc的具体信息如下

```
dimensions:
    y = 12000 ;
    x = 19200 ;
variables:
    float lats(y, x) ;
        lats:_FillValue = -999.f ;
    float lons(y, x) ;
        lons:_FillValue = -999.f ;
    float landuse(y, x) ;
        landuse:_FillValue = -999.f ;
        landuse:coordinates = "lons lats" ;
```

nc2bin的输出格式如下
``` fortran
open(100,file=trim(fname), form='unformatted', iostat=ierror, iomsg=errormg)
     write(100) lats
     write(100) lons
     write(100) array
```

## 更新工具

更新工具的名称为updatelanduse，存放在HOME/src目录中。设计的目的是基于WRF原有的静态数据，只更新其中一种土地利用类型。

**安装**
bash install.sh

**配置**

``` bash
vim input.up
```

配置文件中，原始数据（WRF自带的静态数据集）的配置信息均可在静态数据集中的index文件中获取。
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
  newnx    = 19200       ! x-dimension of new array 新土里利用类型的数据大小
  newny    = 12000       ! y-dimension of new array
  oldindex = 13          ! index of landuse that will be change in raw data 待更新的土地利用类型指数
  newindex = 13          ! index of landuse that will be change in new data
/

&path
  oldpath = "PATH/geog/modis_landuse_20class_30s_with_lakes", !原始的静态数据路径
  newfile = "PATH/asia_landuse.dat", ! 新的土里利用数据
  outpath = "./out", ! 输出路径
/
```

**使用**

``` bash
updatelanduse input.up
```

运行完成后，可将out文件替代modis_landuse_20class_30s_with_lakes文件，在运行WRF即可。

**注意**

更新工具读入的文件格式必须是fortran的无格式文件，按照下面的接口函数转换。

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

具体操作可参见nc2bin。