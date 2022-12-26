## 编译命令

`iverilog main.v -o main` //生成可执行文件

`vvp main` (linux下也可用 `./main` ) //运行

`gtkwave.exe wave.vcd` //生成wave图



要是需要wave图，需要在代码中加入下面几行

```
initial begin            
	$dumpfile("wave.vcd"); //生成的vcd文件名称
	$dumpvars(0, main); //模块名称
end
```





## 可综合/不可综合

可综合：语法结构能与实际硬件电路对应起来

不可综合：语法结构不能与实际硬件电路对应起来



可综合语句：input、output、parameter、reg、wire、always、assign、begin..end、case、posedge、negedge、or、and、default、if、function、generate、integer、`define，while、repeat 、for (while、repeat循环可综合时，要具有明确的循环表达式和循环条件，for可综合时也要有具体的循环范围)



不可综合语句：initial、fork.. join、**wait**、time、**real**、display、 **forever** 、延时控制 #xxx



基本原则：

* 不能使用initial，initial一般使用在测试程序，做初始化；
* 不建议使用延时，#1,这种只是模拟数字电路中因为布线产生的信号延时，不可综合，但也不会报错；
* 不能使用循环次数不确定的函数，但forever在综合设计中禁止使用，只能使用在仿真测试程序中；
* 尽量使用同步电路设计方式(同步电路：电路中所有受时钟控制的单元,全部由一个统一的全局时钟控制)；
* 除非关键电路设计，一般不建议调用门级元件进行设计，一般使用行为级进行设计；
* 当使用always进行组合逻辑设计时，敏感列表里面的要列出所有输入信号。
* 在进行时序电路进行编写时，采用非阻塞赋值。组合逻辑设计时，采用阻塞赋值。在同一个过程块中，最好不要同时用阻塞赋值和非阻塞赋值。
* (?)为避免产生锁存器，if、case要进行完整的语句赋值，且case语句中避免使用X值、Z值。
* 避免混合使用上升沿和下降沿触发的触发器





## 整数表示方法

```verilog
a=8'b1011_1001   //8bit的数值,采用2进制，下划线是为了增强代码的可读性，无实际意义(b:2进制，d：10进制，h：16进制)
a=100;//一般会根据编译器自动分频位宽，常见的为32bit
```



## 有符号数/无符号数转换

```
reg [31:0] a;
reg [31:0] b;
if(a<b) //reg默认为无符号数比较，即按位从高到低比较
if($signed(a)<$signed(b)) //将其转换成有符号数比较
```





## 向量和数组

```verilog
reg[3:0]       A;//向量
reg			   B[3:0]数组
reg[3:0]       C[3:0];//向量的数组
integer        flag[7:0];//整数数组


C[2]=4'b1011;//赋值
```





## x态和z态

x态：未知(可能是0也可能是1)

z态：高阻(高阻态，即悬空状态，例：三极管截断状态时的输出端)



## 阻塞赋值和非阻塞赋值

阻塞赋值顺序执行，顺序会影响我们想要设置的功能

非阻塞赋值同时执行，但是在块语句结束后完成赋值



## assign/wire

```verilog
assign a=b+c; //a一定为wire类型，b,c可以是wire类型或者reg类型
```

assign相当于电路连线，属于组合逻辑



wire是verilog的默认数据类型，即未指定类型的变量都是wire型



## parameter

```verilog
parameters Max=10; //和 const int/define 类似 
```



## always

```verilog
always @ (a or b) begin  //括号内为敏感列表，敏感列表中的任何值发生变化，都会执行always中的指令
	[statements]
end
```

```verilog
always @(posedge clk) begin //在clk上升沿执行always中的指令
	[statements]
end

always @(posedge clk) begin //在module中任意input信号发生变化后执行always中的指令
	[statements]
end
```



 **在描述组合逻辑的always 块中用阻塞赋值** 

```verilog
module combo (	input 	a,
      			input	b,
              	input	c,
              	input	d,
  	            output reg o);

  always @ (a or b or c or d) begin
    o = ~((a & b) | (c^d));
  end

endmodule
```

上面实现了一个简单的组合逻辑



**在描述时序逻辑的always 块中用非阻塞赋值** 

```verilog
module tff (input  		d,
						clk,
						rstn,
			output reg 	q);

	always @ (posedge clk or negedge rstn) begin
		if (!rstn)
			q <= 0;
		else begin
			if (d)
				q <= ~q;
			else
				q <= q;
		 end
	end
endmodule
```

上面实现了一个简单的时序逻辑



## module

module定义

```verilog
module add16(input	[15:0]  a  , 
             input	[15:0]  b  , 
             input		    cin, 
             output	[15:0]  sum, 
             output         cout);
//Module body
endmodule
```

module调用

```verilog
module top_module(
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] sum
);
wire [15:0] sum_low;
wire [15:0] sum_up ;
wire 		cout1  ;
wire 		cout2  ;
add16 instance1(.a		(a[15:0]), 
                .b		(b[15:0]), 
                .cin	(1'b0)	 , 
                .sum	(sum_low), 
                .cout	(cout1));
add16 instance2(.a		(a[31:16]),
                .b		(b[31:16]), 
                .cin	(cout1)   , 
                .sum	(sum_up)  ,
                .cout	(cout2));
assign sum = {sum_up, sum_low};
endmodule

```

instance1，instance2为调用add16模块的两个实例



模块定义时

* input 必须是 wire
* output 可以是 wire/reg
* 不指定为 wire/reg 默认是 wire

模块描述时

* input  端口可以传入 wire/reg
* output 端口必须传出到 wire





## 时延 #xxx

```verilog
always #10 clk = ~clk;//每10个时间单位单位执行一次翻转
```



```verilog
always clk = ~clk;//没有时延，会出问题
```





## 条件语句和循环语句 

**if** 

```
if (condition1)       true_statement1 ;
else if (condition2)        true_statement2 ;
else if (condition3)        true_statement3 ;
else                      default_statement ;
//statement大于一行用begin&end包裹，
```

**case** 

```
case(case_expr)
    condition1     :             true_statement1 ;
    condition2     :             true_statement2 ;
    ……
    default        :             default_statement ;
endcase
//statement大于一行用begin&end包裹，
```

**while** 

```
while (condition) begin
    …
end
```

**for** 

```
for(initial_assignment; condition ; step_assignment)  begin
    …
end
```

**repeat** 

```
repeat (loop_times) begin
    …
end
```

**forever** (不可综合)

```
forever begin
    …
end
```





