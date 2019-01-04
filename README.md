# 土地利用更新工具

部分更新WRF静态数据中的土地利用数据。

## 设计
在WRF的前处理模块（WPS）中，程序geogrid会根据定义的网格信息，计算每个网格的经纬度和投影比例因子，同时，将静态地理数据集（static geographical Data）插值到定义好的区域网格中。

静态数据的好坏直接影响陆-气交换过程，对模式预报效果存在一定的影响，且下垫面数据大多更具历史观测数据统计得来，其更新周期较长，与当前正是的地表情况存在差异。理论上讲，更新下垫面数据，缩小其与真实情况的差异，可以提升局地的预报效果。

由于数据的获取难度，真正能够更新的数据，只有地形和土地利用数据子集。同时，基于GMTED2010（Global Multi-resolution Terrain Elevation Data 2010），WPSv3.8对地形高程数据进行了一次更新，GMTED2010精度在200米以上，基本满足WRF模拟的需求，故没有自己修改的必要。

土地类型子集的统计时间相对较老，且土地利用类型本身相对易变（如城市的扩展等）；从理论上可知，更新局地土地利用类型数据，对预报效果有一定的促进作用。鉴于此，本次WRF静态数据集更新工具的开发，主要针对土地利用数据进行。


更新WFS土地类型（这里的更新是指：更新部分土地利用类型，从头构建一个土地利用类型数据集太难），可以通过两种方式，首先，可以更新WPS生成的```geo_em.d0*.nc```中的LANDUSEF变量，由于针对nc格式进行操作，在读写方面比较方便，但由于每次模拟的区域和分辨率均不一样，可能反而增加了难度；

第二种方式是直接在默认基础数据集上进行更新，一套静态数据子集的网格点是固定，可以针对性的进行替换和处理。但WPS读取的静态数据（2-D或者3-D变量）采用二进制（binary raster format）的形式进行存储，且存储为特定的数据类型（有别于普通的整型、浮点）。因而采用该种方式进行更新的主要难点在于数据的读写。

更新工具设计的原则是一次只更新某一类土地利用类型（如城市用地）；如果要更新多个类型，需要运行多次。



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

安装时注意编译器的选择即可。

``` bash
bash install.sh
```

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