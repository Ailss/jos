
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start-0xc>:
.long MULTIBOOT_HEADER_FLAGS
.long CHECKSUM

.globl		_start
_start:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fb                   	sti    
f0100009:	4f                   	dec    %edi
f010000a:	52                   	push   %edx
f010000b:	e4 66                	in     $0x66,%al

f010000c <_start>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 

	# Establish our own GDT in place of the boot loader's temporary GDT.
	lgdt	RELOC(mygdtdesc)		# load descriptor table
f0100015:	0f 01 15 18 70 11 00 	lgdtl  0x117018

	# Immediately reload all segment registers (including CS!)
	# with segment selectors from the new GDT.
	movl	$DATA_SEL, %eax			# Data segment selector
f010001c:	b8 10 00 00 00       	mov    $0x10,%eax
	movw	%ax,%ds				# -> DS: Data Segment
f0100021:	8e d8                	mov    %eax,%ds
	movw	%ax,%es				# -> ES: Extra Segment
f0100023:	8e c0                	mov    %eax,%es
	movw	%ax,%ss				# -> SS: Stack Segment
f0100025:	8e d0                	mov    %eax,%ss
	ljmp	$CODE_SEL,$relocated		# reload CS by jumping
f0100027:	ea 2e 00 10 f0 08 00 	ljmp   $0x8,$0xf010002e

f010002e <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002e:	bd 00 00 00 00       	mov    $0x0,%ebp

        # Set the stack pointer
	movl	$(bootstacktop),%esp
f0100033:	bc 00 70 11 f0       	mov    $0xf0117000,%esp

	# now to C code
	call	i386_init
f0100038:	e8 02 00 00 00       	call   f010003f <i386_init>

f010003d <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003d:	eb fe                	jmp    f010003d <spin>

f010003f <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f010003f:	55                   	push   %ebp
f0100040:	89 e5                	mov    %esp,%ebp
f0100042:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100045:	ba 30 7c 11 f0       	mov    $0xf0117c30,%edx
f010004a:	b8 96 75 11 f0       	mov    $0xf0117596,%eax
f010004f:	29 c2                	sub    %eax,%edx
f0100051:	89 d0                	mov    %edx,%eax
f0100053:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100057:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005e:	00 
f010005f:	c7 04 24 96 75 11 f0 	movl   $0xf0117596,(%esp)
f0100066:	e8 22 43 00 00       	call   f010438d <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010006b:	e8 14 08 00 00       	call   f0100884 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100070:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100077:	00 
f0100078:	c7 04 24 d8 48 10 f0 	movl   $0xf01048d8,(%esp)
f010007f:	e8 84 34 00 00       	call   f0103508 <cprintf>

	// Lab 2 memory management initialization functions
	i386_detect_memory();
f0100084:	e8 19 0d 00 00       	call   f0100da2 <i386_detect_memory>
	i386_vm_init();
f0100089:	e8 30 0e 00 00       	call   f0100ebe <i386_vm_init>



	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010008e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100095:	e8 a9 0b 00 00       	call   f0100c43 <monitor>
f010009a:	eb f2                	jmp    f010008e <i386_init+0x4f>

f010009c <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010009c:	55                   	push   %ebp
f010009d:	89 e5                	mov    %esp,%ebp
f010009f:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	if (panicstr)
f01000a2:	a1 a0 75 11 f0       	mov    0xf01175a0,%eax
f01000a7:	85 c0                	test   %eax,%eax
f01000a9:	74 02                	je     f01000ad <_panic+0x11>
		goto dead;
f01000ab:	eb 49                	jmp    f01000f6 <_panic+0x5a>
	panicstr = fmt;
f01000ad:	8b 45 10             	mov    0x10(%ebp),%eax
f01000b0:	a3 a0 75 11 f0       	mov    %eax,0xf01175a0

	va_start(ap, fmt);
f01000b5:	8d 45 10             	lea    0x10(%ebp),%eax
f01000b8:	83 c0 04             	add    $0x4,%eax
f01000bb:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
f01000be:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000c1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01000c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000cc:	c7 04 24 f3 48 10 f0 	movl   $0xf01048f3,(%esp)
f01000d3:	e8 30 34 00 00       	call   f0103508 <cprintf>
	vcprintf(fmt, ap);
f01000d8:	8b 45 10             	mov    0x10(%ebp),%eax
f01000db:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01000de:	89 54 24 04          	mov    %edx,0x4(%esp)
f01000e2:	89 04 24             	mov    %eax,(%esp)
f01000e5:	e8 eb 33 00 00       	call   f01034d5 <vcprintf>
	cprintf("\n");
f01000ea:	c7 04 24 0b 49 10 f0 	movl   $0xf010490b,(%esp)
f01000f1:	e8 12 34 00 00       	call   f0103508 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000f6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000fd:	e8 41 0b 00 00       	call   f0100c43 <monitor>
f0100102:	eb f2                	jmp    f01000f6 <_panic+0x5a>

f0100104 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100104:	55                   	push   %ebp
f0100105:	89 e5                	mov    %esp,%ebp
f0100107:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
f010010a:	8d 45 10             	lea    0x10(%ebp),%eax
f010010d:	83 c0 04             	add    $0x4,%eax
f0100110:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
f0100113:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100116:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011a:	8b 45 08             	mov    0x8(%ebp),%eax
f010011d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100121:	c7 04 24 0d 49 10 f0 	movl   $0xf010490d,(%esp)
f0100128:	e8 db 33 00 00       	call   f0103508 <cprintf>
	vcprintf(fmt, ap);
f010012d:	8b 45 10             	mov    0x10(%ebp),%eax
f0100130:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100133:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100137:	89 04 24             	mov    %eax,(%esp)
f010013a:	e8 96 33 00 00       	call   f01034d5 <vcprintf>
	cprintf("\n");
f010013f:	c7 04 24 0b 49 10 f0 	movl   $0xf010490b,(%esp)
f0100146:	e8 bd 33 00 00       	call   f0103508 <cprintf>
	va_end(ap);
}
f010014b:	c9                   	leave  
f010014c:	c3                   	ret    

f010014d <serial_proc_data>:

static bool serial_exists;

int
serial_proc_data(void)
{
f010014d:	55                   	push   %ebp
f010014e:	89 e5                	mov    %esp,%ebp
f0100150:	83 ec 10             	sub    $0x10,%esp
f0100153:	c7 45 fc fd 03 00 00 	movl   $0x3fd,-0x4(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010015a:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010015d:	89 c2                	mov    %eax,%edx
f010015f:	ec                   	in     (%dx),%al
f0100160:	88 45 fb             	mov    %al,-0x5(%ebp)
	return data;
f0100163:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100167:	0f b6 c0             	movzbl %al,%eax
f010016a:	83 e0 01             	and    $0x1,%eax
f010016d:	85 c0                	test   %eax,%eax
f010016f:	75 07                	jne    f0100178 <serial_proc_data+0x2b>
		return -1;
f0100171:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100176:	eb 17                	jmp    f010018f <serial_proc_data+0x42>
f0100178:	c7 45 f4 f8 03 00 00 	movl   $0x3f8,-0xc(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100182:	89 c2                	mov    %eax,%edx
f0100184:	ec                   	in     (%dx),%al
f0100185:	88 45 f3             	mov    %al,-0xd(%ebp)
	return data;
f0100188:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
	return inb(COM1+COM_RX);
f010018c:	0f b6 c0             	movzbl %al,%eax
}
f010018f:	c9                   	leave  
f0100190:	c3                   	ret    

f0100191 <serial_intr>:

void
serial_intr(void)
{
f0100191:	55                   	push   %ebp
f0100192:	89 e5                	mov    %esp,%ebp
f0100194:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
f0100197:	a1 c0 75 11 f0       	mov    0xf01175c0,%eax
f010019c:	85 c0                	test   %eax,%eax
f010019e:	74 0c                	je     f01001ac <serial_intr+0x1b>
		cons_intr(serial_proc_data);
f01001a0:	c7 04 24 4d 01 10 f0 	movl   $0xf010014d,(%esp)
f01001a7:	e8 11 06 00 00       	call   f01007bd <cons_intr>
}
f01001ac:	c9                   	leave  
f01001ad:	c3                   	ret    

f01001ae <serial_init>:

void
serial_init(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	83 ec 50             	sub    $0x50,%esp
f01001b4:	c7 45 fc fa 03 00 00 	movl   $0x3fa,-0x4(%ebp)
f01001bb:	c6 45 fb 00          	movb   $0x0,-0x5(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001bf:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
f01001c3:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01001c6:	ee                   	out    %al,(%dx)
f01001c7:	c7 45 f4 fb 03 00 00 	movl   $0x3fb,-0xc(%ebp)
f01001ce:	c6 45 f3 80          	movb   $0x80,-0xd(%ebp)
f01001d2:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f01001d6:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01001d9:	ee                   	out    %al,(%dx)
f01001da:	c7 45 ec f8 03 00 00 	movl   $0x3f8,-0x14(%ebp)
f01001e1:	c6 45 eb 0c          	movb   $0xc,-0x15(%ebp)
f01001e5:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
f01001e9:	8b 55 ec             	mov    -0x14(%ebp),%edx
f01001ec:	ee                   	out    %al,(%dx)
f01001ed:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
f01001f4:	c6 45 e3 00          	movb   $0x0,-0x1d(%ebp)
f01001f8:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f01001fc:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01001ff:	ee                   	out    %al,(%dx)
f0100200:	c7 45 dc fb 03 00 00 	movl   $0x3fb,-0x24(%ebp)
f0100207:	c6 45 db 03          	movb   $0x3,-0x25(%ebp)
f010020b:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
f010020f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100212:	ee                   	out    %al,(%dx)
f0100213:	c7 45 d4 fc 03 00 00 	movl   $0x3fc,-0x2c(%ebp)
f010021a:	c6 45 d3 00          	movb   $0x0,-0x2d(%ebp)
f010021e:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
f0100222:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100225:	ee                   	out    %al,(%dx)
f0100226:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
f010022d:	c6 45 cb 01          	movb   $0x1,-0x35(%ebp)
f0100231:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
f0100235:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0100238:	ee                   	out    %al,(%dx)
f0100239:	c7 45 c4 fd 03 00 00 	movl   $0x3fd,-0x3c(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100240:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100243:	89 c2                	mov    %eax,%edx
f0100245:	ec                   	in     (%dx),%al
f0100246:	88 45 c3             	mov    %al,-0x3d(%ebp)
	return data;
f0100249:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010024d:	3c ff                	cmp    $0xff,%al
f010024f:	0f 95 c0             	setne  %al
f0100252:	0f b6 c0             	movzbl %al,%eax
f0100255:	a3 c0 75 11 f0       	mov    %eax,0xf01175c0
f010025a:	c7 45 bc fa 03 00 00 	movl   $0x3fa,-0x44(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100261:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0100264:	89 c2                	mov    %eax,%edx
f0100266:	ec                   	in     (%dx),%al
f0100267:	88 45 bb             	mov    %al,-0x45(%ebp)
f010026a:	c7 45 b4 f8 03 00 00 	movl   $0x3f8,-0x4c(%ebp)
f0100271:	8b 45 b4             	mov    -0x4c(%ebp),%eax
f0100274:	89 c2                	mov    %eax,%edx
f0100276:	ec                   	in     (%dx),%al
f0100277:	88 45 b3             	mov    %al,-0x4d(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

}
f010027a:	c9                   	leave  
f010027b:	c3                   	ret    

f010027c <delay>:
// page.

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f010027c:	55                   	push   %ebp
f010027d:	89 e5                	mov    %esp,%ebp
f010027f:	83 ec 20             	sub    $0x20,%esp
f0100282:	c7 45 fc 84 00 00 00 	movl   $0x84,-0x4(%ebp)
f0100289:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010028c:	89 c2                	mov    %eax,%edx
f010028e:	ec                   	in     (%dx),%al
f010028f:	88 45 fb             	mov    %al,-0x5(%ebp)
f0100292:	c7 45 f4 84 00 00 00 	movl   $0x84,-0xc(%ebp)
f0100299:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010029c:	89 c2                	mov    %eax,%edx
f010029e:	ec                   	in     (%dx),%al
f010029f:	88 45 f3             	mov    %al,-0xd(%ebp)
f01002a2:	c7 45 ec 84 00 00 00 	movl   $0x84,-0x14(%ebp)
f01002a9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01002ac:	89 c2                	mov    %eax,%edx
f01002ae:	ec                   	in     (%dx),%al
f01002af:	88 45 eb             	mov    %al,-0x15(%ebp)
f01002b2:	c7 45 e4 84 00 00 00 	movl   $0x84,-0x1c(%ebp)
f01002b9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01002bc:	89 c2                	mov    %eax,%edx
f01002be:	ec                   	in     (%dx),%al
f01002bf:	88 45 e3             	mov    %al,-0x1d(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01002c2:	c9                   	leave  
f01002c3:	c3                   	ret    

f01002c4 <lpt_putc>:

static void
lpt_putc(int c)
{
f01002c4:	55                   	push   %ebp
f01002c5:	89 e5                	mov    %esp,%ebp
f01002c7:	83 ec 30             	sub    $0x30,%esp
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002ca:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f01002d1:	eb 09                	jmp    f01002dc <lpt_putc+0x18>
		delay();
f01002d3:	e8 a4 ff ff ff       	call   f010027c <delay>
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002d8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f01002dc:	c7 45 f8 79 03 00 00 	movl   $0x379,-0x8(%ebp)
f01002e3:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01002e6:	89 c2                	mov    %eax,%edx
f01002e8:	ec                   	in     (%dx),%al
f01002e9:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
f01002ec:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
f01002f0:	84 c0                	test   %al,%al
f01002f2:	78 09                	js     f01002fd <lpt_putc+0x39>
f01002f4:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
f01002fb:	7e d6                	jle    f01002d3 <lpt_putc+0xf>
		delay();
	outb(0x378+0, c);
f01002fd:	8b 45 08             	mov    0x8(%ebp),%eax
f0100300:	0f b6 c0             	movzbl %al,%eax
f0100303:	c7 45 f0 78 03 00 00 	movl   $0x378,-0x10(%ebp)
f010030a:	88 45 ef             	mov    %al,-0x11(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010030d:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
f0100311:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100314:	ee                   	out    %al,(%dx)
f0100315:	c7 45 e8 7a 03 00 00 	movl   $0x37a,-0x18(%ebp)
f010031c:	c6 45 e7 0d          	movb   $0xd,-0x19(%ebp)
f0100320:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100324:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100327:	ee                   	out    %al,(%dx)
f0100328:	c7 45 e0 7a 03 00 00 	movl   $0x37a,-0x20(%ebp)
f010032f:	c6 45 df 08          	movb   $0x8,-0x21(%ebp)
f0100333:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
f0100337:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010033a:	ee                   	out    %al,(%dx)
	outb(0x378+2, 0x08|0x04|0x01);
	outb(0x378+2, 0x08);
}
f010033b:	c9                   	leave  
f010033c:	c3                   	ret    

f010033d <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
cga_init(void)
{
f010033d:	55                   	push   %ebp
f010033e:	89 e5                	mov    %esp,%ebp
f0100340:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100343:	c7 45 fc 00 80 0b f0 	movl   $0xf00b8000,-0x4(%ebp)
	was = *cp;
f010034a:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010034d:	0f b7 00             	movzwl (%eax),%eax
f0100350:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
	*cp = (uint16_t) 0xA55A;
f0100354:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100357:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
f010035c:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010035f:	0f b7 00             	movzwl (%eax),%eax
f0100362:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100366:	74 13                	je     f010037b <cga_init+0x3e>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100368:	c7 45 fc 00 00 0b f0 	movl   $0xf00b0000,-0x4(%ebp)
		addr_6845 = MONO_BASE;
f010036f:	c7 05 c4 75 11 f0 b4 	movl   $0x3b4,0xf01175c4
f0100376:	03 00 00 
f0100379:	eb 14                	jmp    f010038f <cga_init+0x52>
	} else {
		*cp = was;
f010037b:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010037e:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
f0100382:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
f0100385:	c7 05 c4 75 11 f0 d4 	movl   $0x3d4,0xf01175c4
f010038c:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f010038f:	a1 c4 75 11 f0       	mov    0xf01175c4,%eax
f0100394:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100397:	c6 45 ef 0e          	movb   $0xe,-0x11(%ebp)
f010039b:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
f010039f:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01003a2:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01003a3:	a1 c4 75 11 f0       	mov    0xf01175c4,%eax
f01003a8:	83 c0 01             	add    $0x1,%eax
f01003ab:	89 45 e8             	mov    %eax,-0x18(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003ae:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01003b1:	89 c2                	mov    %eax,%edx
f01003b3:	ec                   	in     (%dx),%al
f01003b4:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
f01003b7:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f01003bb:	0f b6 c0             	movzbl %al,%eax
f01003be:	c1 e0 08             	shl    $0x8,%eax
f01003c1:	89 45 f4             	mov    %eax,-0xc(%ebp)
	outb(addr_6845, 15);
f01003c4:	a1 c4 75 11 f0       	mov    0xf01175c4,%eax
f01003c9:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01003cc:	c6 45 df 0f          	movb   $0xf,-0x21(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003d0:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
f01003d4:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01003d7:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
f01003d8:	a1 c4 75 11 f0       	mov    0xf01175c4,%eax
f01003dd:	83 c0 01             	add    $0x1,%eax
f01003e0:	89 45 d8             	mov    %eax,-0x28(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003e3:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01003e6:	89 c2                	mov    %eax,%edx
f01003e8:	ec                   	in     (%dx),%al
f01003e9:	88 45 d7             	mov    %al,-0x29(%ebp)
	return data;
f01003ec:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
f01003f0:	0f b6 c0             	movzbl %al,%eax
f01003f3:	09 45 f4             	or     %eax,-0xc(%ebp)

	crt_buf = (uint16_t*) cp;
f01003f6:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01003f9:	a3 c8 75 11 f0       	mov    %eax,0xf01175c8
	crt_pos = pos;
f01003fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100401:	66 a3 cc 75 11 f0    	mov    %ax,0xf01175cc
}
f0100407:	c9                   	leave  
f0100408:	c3                   	ret    

f0100409 <cga_putc>:



void
cga_putc(int c)
{
f0100409:	55                   	push   %ebp
f010040a:	89 e5                	mov    %esp,%ebp
f010040c:	53                   	push   %ebx
f010040d:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100410:	8b 45 08             	mov    0x8(%ebp),%eax
f0100413:	b0 00                	mov    $0x0,%al
f0100415:	85 c0                	test   %eax,%eax
f0100417:	75 07                	jne    f0100420 <cga_putc+0x17>
		c |= 0x0500;
f0100419:	81 4d 08 00 05 00 00 	orl    $0x500,0x8(%ebp)

	switch (c & 0xff) {
f0100420:	8b 45 08             	mov    0x8(%ebp),%eax
f0100423:	0f b6 c0             	movzbl %al,%eax
f0100426:	83 f8 09             	cmp    $0x9,%eax
f0100429:	0f 84 ac 00 00 00    	je     f01004db <cga_putc+0xd2>
f010042f:	83 f8 09             	cmp    $0x9,%eax
f0100432:	7f 0a                	jg     f010043e <cga_putc+0x35>
f0100434:	83 f8 08             	cmp    $0x8,%eax
f0100437:	74 14                	je     f010044d <cga_putc+0x44>
f0100439:	e9 db 00 00 00       	jmp    f0100519 <cga_putc+0x110>
f010043e:	83 f8 0a             	cmp    $0xa,%eax
f0100441:	74 4e                	je     f0100491 <cga_putc+0x88>
f0100443:	83 f8 0d             	cmp    $0xd,%eax
f0100446:	74 59                	je     f01004a1 <cga_putc+0x98>
f0100448:	e9 cc 00 00 00       	jmp    f0100519 <cga_putc+0x110>
	case '\b':
		if (crt_pos > 0) {
f010044d:	0f b7 05 cc 75 11 f0 	movzwl 0xf01175cc,%eax
f0100454:	66 85 c0             	test   %ax,%ax
f0100457:	74 33                	je     f010048c <cga_putc+0x83>
			crt_pos--;
f0100459:	0f b7 05 cc 75 11 f0 	movzwl 0xf01175cc,%eax
f0100460:	83 e8 01             	sub    $0x1,%eax
f0100463:	66 a3 cc 75 11 f0    	mov    %ax,0xf01175cc
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100469:	a1 c8 75 11 f0       	mov    0xf01175c8,%eax
f010046e:	0f b7 15 cc 75 11 f0 	movzwl 0xf01175cc,%edx
f0100475:	0f b7 d2             	movzwl %dx,%edx
f0100478:	01 d2                	add    %edx,%edx
f010047a:	01 c2                	add    %eax,%edx
f010047c:	8b 45 08             	mov    0x8(%ebp),%eax
f010047f:	b0 00                	mov    $0x0,%al
f0100481:	83 c8 20             	or     $0x20,%eax
f0100484:	66 89 02             	mov    %ax,(%edx)
		}
		break;
f0100487:	e9 b3 00 00 00       	jmp    f010053f <cga_putc+0x136>
f010048c:	e9 ae 00 00 00       	jmp    f010053f <cga_putc+0x136>
	case '\n':
		crt_pos += CRT_COLS;
f0100491:	0f b7 05 cc 75 11 f0 	movzwl 0xf01175cc,%eax
f0100498:	83 c0 50             	add    $0x50,%eax
f010049b:	66 a3 cc 75 11 f0    	mov    %ax,0xf01175cc
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004a1:	0f b7 1d cc 75 11 f0 	movzwl 0xf01175cc,%ebx
f01004a8:	0f b7 0d cc 75 11 f0 	movzwl 0xf01175cc,%ecx
f01004af:	0f b7 c1             	movzwl %cx,%eax
f01004b2:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004b8:	c1 e8 10             	shr    $0x10,%eax
f01004bb:	89 c2                	mov    %eax,%edx
f01004bd:	66 c1 ea 06          	shr    $0x6,%dx
f01004c1:	89 d0                	mov    %edx,%eax
f01004c3:	c1 e0 02             	shl    $0x2,%eax
f01004c6:	01 d0                	add    %edx,%eax
f01004c8:	c1 e0 04             	shl    $0x4,%eax
f01004cb:	29 c1                	sub    %eax,%ecx
f01004cd:	89 ca                	mov    %ecx,%edx
f01004cf:	89 d8                	mov    %ebx,%eax
f01004d1:	29 d0                	sub    %edx,%eax
f01004d3:	66 a3 cc 75 11 f0    	mov    %ax,0xf01175cc
		break;
f01004d9:	eb 64                	jmp    f010053f <cga_putc+0x136>
	case '\t':
		cons_putc(' ');
f01004db:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01004e2:	e8 7f 03 00 00       	call   f0100866 <cons_putc>
		cons_putc(' ');
f01004e7:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01004ee:	e8 73 03 00 00       	call   f0100866 <cons_putc>
		cons_putc(' ');
f01004f3:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01004fa:	e8 67 03 00 00       	call   f0100866 <cons_putc>
		cons_putc(' ');
f01004ff:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100506:	e8 5b 03 00 00       	call   f0100866 <cons_putc>
		cons_putc(' ');
f010050b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100512:	e8 4f 03 00 00       	call   f0100866 <cons_putc>
		break;
f0100517:	eb 26                	jmp    f010053f <cga_putc+0x136>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100519:	8b 0d c8 75 11 f0    	mov    0xf01175c8,%ecx
f010051f:	0f b7 05 cc 75 11 f0 	movzwl 0xf01175cc,%eax
f0100526:	8d 50 01             	lea    0x1(%eax),%edx
f0100529:	66 89 15 cc 75 11 f0 	mov    %dx,0xf01175cc
f0100530:	0f b7 c0             	movzwl %ax,%eax
f0100533:	01 c0                	add    %eax,%eax
f0100535:	8d 14 01             	lea    (%ecx,%eax,1),%edx
f0100538:	8b 45 08             	mov    0x8(%ebp),%eax
f010053b:	66 89 02             	mov    %ax,(%edx)
		break;
f010053e:	90                   	nop
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010053f:	0f b7 05 cc 75 11 f0 	movzwl 0xf01175cc,%eax
f0100546:	66 3d cf 07          	cmp    $0x7cf,%ax
f010054a:	76 5b                	jbe    f01005a7 <cga_putc+0x19e>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010054c:	a1 c8 75 11 f0       	mov    0xf01175c8,%eax
f0100551:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100557:	a1 c8 75 11 f0       	mov    0xf01175c8,%eax
f010055c:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100563:	00 
f0100564:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100568:	89 04 24             	mov    %eax,(%esp)
f010056b:	e8 4e 3e 00 00       	call   f01043be <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100570:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
f0100577:	eb 15                	jmp    f010058e <cga_putc+0x185>
			crt_buf[i] = 0x0700 | ' ';
f0100579:	a1 c8 75 11 f0       	mov    0xf01175c8,%eax
f010057e:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100581:	01 d2                	add    %edx,%edx
f0100583:	01 d0                	add    %edx,%eax
f0100585:	66 c7 00 20 07       	movw   $0x720,(%eax)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010058a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
f010058e:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
f0100595:	7e e2                	jle    f0100579 <cga_putc+0x170>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100597:	0f b7 05 cc 75 11 f0 	movzwl 0xf01175cc,%eax
f010059e:	83 e8 50             	sub    $0x50,%eax
f01005a1:	66 a3 cc 75 11 f0    	mov    %ax,0xf01175cc
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005a7:	a1 c4 75 11 f0       	mov    0xf01175c4,%eax
f01005ac:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01005af:	c6 45 ef 0e          	movb   $0xe,-0x11(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005b3:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
f01005b7:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01005ba:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005bb:	0f b7 05 cc 75 11 f0 	movzwl 0xf01175cc,%eax
f01005c2:	66 c1 e8 08          	shr    $0x8,%ax
f01005c6:	0f b6 c0             	movzbl %al,%eax
f01005c9:	8b 15 c4 75 11 f0    	mov    0xf01175c4,%edx
f01005cf:	83 c2 01             	add    $0x1,%edx
f01005d2:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01005d5:	88 45 e7             	mov    %al,-0x19(%ebp)
f01005d8:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f01005dc:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01005df:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
f01005e0:	a1 c4 75 11 f0       	mov    0xf01175c4,%eax
f01005e5:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01005e8:	c6 45 df 0f          	movb   $0xf,-0x21(%ebp)
f01005ec:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
f01005f0:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01005f3:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
f01005f4:	0f b7 05 cc 75 11 f0 	movzwl 0xf01175cc,%eax
f01005fb:	0f b6 c0             	movzbl %al,%eax
f01005fe:	8b 15 c4 75 11 f0    	mov    0xf01175c4,%edx
f0100604:	83 c2 01             	add    $0x1,%edx
f0100607:	89 55 d8             	mov    %edx,-0x28(%ebp)
f010060a:	88 45 d7             	mov    %al,-0x29(%ebp)
f010060d:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
f0100611:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100614:	ee                   	out    %al,(%dx)
}
f0100615:	83 c4 44             	add    $0x44,%esp
f0100618:	5b                   	pop    %ebx
f0100619:	5d                   	pop    %ebp
f010061a:	c3                   	ret    

f010061b <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010061b:	55                   	push   %ebp
f010061c:	89 e5                	mov    %esp,%ebp
f010061e:	83 ec 38             	sub    $0x38,%esp
f0100621:	c7 45 ec 64 00 00 00 	movl   $0x64,-0x14(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100628:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010062b:	89 c2                	mov    %eax,%edx
f010062d:	ec                   	in     (%dx),%al
f010062e:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
f0100631:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100635:	0f b6 c0             	movzbl %al,%eax
f0100638:	83 e0 01             	and    $0x1,%eax
f010063b:	85 c0                	test   %eax,%eax
f010063d:	75 0a                	jne    f0100649 <kbd_proc_data+0x2e>
		return -1;
f010063f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100644:	e9 59 01 00 00       	jmp    f01007a2 <kbd_proc_data+0x187>
f0100649:	c7 45 e4 60 00 00 00 	movl   $0x60,-0x1c(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100650:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100653:	89 c2                	mov    %eax,%edx
f0100655:	ec                   	in     (%dx),%al
f0100656:	88 45 e3             	mov    %al,-0x1d(%ebp)
	return data;
f0100659:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax

	data = inb(KBDATAP);
f010065d:	88 45 f3             	mov    %al,-0xd(%ebp)

	if (data == 0xE0) {
f0100660:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
f0100664:	75 17                	jne    f010067d <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
f0100666:	a1 e8 77 11 f0       	mov    0xf01177e8,%eax
f010066b:	83 c8 40             	or     $0x40,%eax
f010066e:	a3 e8 77 11 f0       	mov    %eax,0xf01177e8
		return 0;
f0100673:	b8 00 00 00 00       	mov    $0x0,%eax
f0100678:	e9 25 01 00 00       	jmp    f01007a2 <kbd_proc_data+0x187>
	} else if (data & 0x80) {
f010067d:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f0100681:	84 c0                	test   %al,%al
f0100683:	79 47                	jns    f01006cc <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100685:	a1 e8 77 11 f0       	mov    0xf01177e8,%eax
f010068a:	83 e0 40             	and    $0x40,%eax
f010068d:	85 c0                	test   %eax,%eax
f010068f:	75 09                	jne    f010069a <kbd_proc_data+0x7f>
f0100691:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f0100695:	83 e0 7f             	and    $0x7f,%eax
f0100698:	eb 04                	jmp    f010069e <kbd_proc_data+0x83>
f010069a:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f010069e:	88 45 f3             	mov    %al,-0xd(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
f01006a1:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f01006a5:	0f b6 80 20 70 11 f0 	movzbl -0xfee8fe0(%eax),%eax
f01006ac:	83 c8 40             	or     $0x40,%eax
f01006af:	0f b6 c0             	movzbl %al,%eax
f01006b2:	f7 d0                	not    %eax
f01006b4:	89 c2                	mov    %eax,%edx
f01006b6:	a1 e8 77 11 f0       	mov    0xf01177e8,%eax
f01006bb:	21 d0                	and    %edx,%eax
f01006bd:	a3 e8 77 11 f0       	mov    %eax,0xf01177e8
		return 0;
f01006c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01006c7:	e9 d6 00 00 00       	jmp    f01007a2 <kbd_proc_data+0x187>
	} else if (shift & E0ESC) {
f01006cc:	a1 e8 77 11 f0       	mov    0xf01177e8,%eax
f01006d1:	83 e0 40             	and    $0x40,%eax
f01006d4:	85 c0                	test   %eax,%eax
f01006d6:	74 11                	je     f01006e9 <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01006d8:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
		shift &= ~E0ESC;
f01006dc:	a1 e8 77 11 f0       	mov    0xf01177e8,%eax
f01006e1:	83 e0 bf             	and    $0xffffffbf,%eax
f01006e4:	a3 e8 77 11 f0       	mov    %eax,0xf01177e8
	}

	shift |= shiftcode[data];
f01006e9:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f01006ed:	0f b6 80 20 70 11 f0 	movzbl -0xfee8fe0(%eax),%eax
f01006f4:	0f b6 d0             	movzbl %al,%edx
f01006f7:	a1 e8 77 11 f0       	mov    0xf01177e8,%eax
f01006fc:	09 d0                	or     %edx,%eax
f01006fe:	a3 e8 77 11 f0       	mov    %eax,0xf01177e8
	shift ^= togglecode[data];
f0100703:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f0100707:	0f b6 80 20 71 11 f0 	movzbl -0xfee8ee0(%eax),%eax
f010070e:	0f b6 d0             	movzbl %al,%edx
f0100711:	a1 e8 77 11 f0       	mov    0xf01177e8,%eax
f0100716:	31 d0                	xor    %edx,%eax
f0100718:	a3 e8 77 11 f0       	mov    %eax,0xf01177e8

	c = charcode[shift & (CTL | SHIFT)][data];
f010071d:	a1 e8 77 11 f0       	mov    0xf01177e8,%eax
f0100722:	83 e0 03             	and    $0x3,%eax
f0100725:	8b 14 85 20 75 11 f0 	mov    -0xfee8ae0(,%eax,4),%edx
f010072c:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f0100730:	01 d0                	add    %edx,%eax
f0100732:	0f b6 00             	movzbl (%eax),%eax
f0100735:	0f b6 c0             	movzbl %al,%eax
f0100738:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (shift & CAPSLOCK) {
f010073b:	a1 e8 77 11 f0       	mov    0xf01177e8,%eax
f0100740:	83 e0 08             	and    $0x8,%eax
f0100743:	85 c0                	test   %eax,%eax
f0100745:	74 22                	je     f0100769 <kbd_proc_data+0x14e>
		if ('a' <= c && c <= 'z')
f0100747:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
f010074b:	7e 0c                	jle    f0100759 <kbd_proc_data+0x13e>
f010074d:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
f0100751:	7f 06                	jg     f0100759 <kbd_proc_data+0x13e>
			c += 'A' - 'a';
f0100753:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
f0100757:	eb 10                	jmp    f0100769 <kbd_proc_data+0x14e>
		else if ('A' <= c && c <= 'Z')
f0100759:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
f010075d:	7e 0a                	jle    f0100769 <kbd_proc_data+0x14e>
f010075f:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
f0100763:	7f 04                	jg     f0100769 <kbd_proc_data+0x14e>
			c += 'a' - 'A';
f0100765:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100769:	a1 e8 77 11 f0       	mov    0xf01177e8,%eax
f010076e:	f7 d0                	not    %eax
f0100770:	83 e0 06             	and    $0x6,%eax
f0100773:	85 c0                	test   %eax,%eax
f0100775:	75 28                	jne    f010079f <kbd_proc_data+0x184>
f0100777:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
f010077e:	75 1f                	jne    f010079f <kbd_proc_data+0x184>
		cprintf("Rebooting!\n");
f0100780:	c7 04 24 27 49 10 f0 	movl   $0xf0104927,(%esp)
f0100787:	e8 7c 2d 00 00       	call   f0103508 <cprintf>
f010078c:	c7 45 dc 92 00 00 00 	movl   $0x92,-0x24(%ebp)
f0100793:	c6 45 db 03          	movb   $0x3,-0x25(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100797:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
f010079b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010079e:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010079f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f01007a2:	c9                   	leave  
f01007a3:	c3                   	ret    

f01007a4 <kbd_intr>:

void
kbd_intr(void)
{
f01007a4:	55                   	push   %ebp
f01007a5:	89 e5                	mov    %esp,%ebp
f01007a7:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
f01007aa:	c7 04 24 1b 06 10 f0 	movl   $0xf010061b,(%esp)
f01007b1:	e8 07 00 00 00       	call   f01007bd <cons_intr>
}
f01007b6:	c9                   	leave  
f01007b7:	c3                   	ret    

f01007b8 <kbd_init>:

void
kbd_init(void)
{
f01007b8:	55                   	push   %ebp
f01007b9:	89 e5                	mov    %esp,%ebp
}
f01007bb:	5d                   	pop    %ebp
f01007bc:	c3                   	ret    

f01007bd <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
f01007bd:	55                   	push   %ebp
f01007be:	89 e5                	mov    %esp,%ebp
f01007c0:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = (*proc)()) != -1) {
f01007c3:	eb 35                	jmp    f01007fa <cons_intr+0x3d>
		if (c == 0)
f01007c5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f01007c9:	75 02                	jne    f01007cd <cons_intr+0x10>
			continue;
f01007cb:	eb 2d                	jmp    f01007fa <cons_intr+0x3d>
		cons.buf[cons.wpos++] = c;
f01007cd:	a1 e4 77 11 f0       	mov    0xf01177e4,%eax
f01007d2:	8d 50 01             	lea    0x1(%eax),%edx
f01007d5:	89 15 e4 77 11 f0    	mov    %edx,0xf01177e4
f01007db:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01007de:	88 90 e0 75 11 f0    	mov    %dl,-0xfee8a20(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01007e4:	a1 e4 77 11 f0       	mov    0xf01177e4,%eax
f01007e9:	3d 00 02 00 00       	cmp    $0x200,%eax
f01007ee:	75 0a                	jne    f01007fa <cons_intr+0x3d>
			cons.wpos = 0;
f01007f0:	c7 05 e4 77 11 f0 00 	movl   $0x0,0xf01177e4
f01007f7:	00 00 00 
void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01007fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01007fd:	ff d0                	call   *%eax
f01007ff:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100802:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
f0100806:	75 bd                	jne    f01007c5 <cons_intr+0x8>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100808:	c9                   	leave  
f0100809:	c3                   	ret    

f010080a <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010080a:	55                   	push   %ebp
f010080b:	89 e5                	mov    %esp,%ebp
f010080d:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100810:	e8 7c f9 ff ff       	call   f0100191 <serial_intr>
	kbd_intr();
f0100815:	e8 8a ff ff ff       	call   f01007a4 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010081a:	8b 15 e0 77 11 f0    	mov    0xf01177e0,%edx
f0100820:	a1 e4 77 11 f0       	mov    0xf01177e4,%eax
f0100825:	39 c2                	cmp    %eax,%edx
f0100827:	74 36                	je     f010085f <cons_getc+0x55>
		c = cons.buf[cons.rpos++];
f0100829:	a1 e0 77 11 f0       	mov    0xf01177e0,%eax
f010082e:	8d 50 01             	lea    0x1(%eax),%edx
f0100831:	89 15 e0 77 11 f0    	mov    %edx,0xf01177e0
f0100837:	0f b6 80 e0 75 11 f0 	movzbl -0xfee8a20(%eax),%eax
f010083e:	0f b6 c0             	movzbl %al,%eax
f0100841:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if (cons.rpos == CONSBUFSIZE)
f0100844:	a1 e0 77 11 f0       	mov    0xf01177e0,%eax
f0100849:	3d 00 02 00 00       	cmp    $0x200,%eax
f010084e:	75 0a                	jne    f010085a <cons_getc+0x50>
			cons.rpos = 0;
f0100850:	c7 05 e0 77 11 f0 00 	movl   $0x0,0xf01177e0
f0100857:	00 00 00 
		return c;
f010085a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010085d:	eb 05                	jmp    f0100864 <cons_getc+0x5a>
	}
	return 0;
f010085f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100864:	c9                   	leave  
f0100865:	c3                   	ret    

f0100866 <cons_putc>:

// output a character to the console
void
cons_putc(int c)
{
f0100866:	55                   	push   %ebp
f0100867:	89 e5                	mov    %esp,%ebp
f0100869:	83 ec 18             	sub    $0x18,%esp
	lpt_putc(c);
f010086c:	8b 45 08             	mov    0x8(%ebp),%eax
f010086f:	89 04 24             	mov    %eax,(%esp)
f0100872:	e8 4d fa ff ff       	call   f01002c4 <lpt_putc>
	cga_putc(c);
f0100877:	8b 45 08             	mov    0x8(%ebp),%eax
f010087a:	89 04 24             	mov    %eax,(%esp)
f010087d:	e8 87 fb ff ff       	call   f0100409 <cga_putc>
}
f0100882:	c9                   	leave  
f0100883:	c3                   	ret    

f0100884 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f0100884:	55                   	push   %ebp
f0100885:	89 e5                	mov    %esp,%ebp
f0100887:	83 ec 18             	sub    $0x18,%esp
	cga_init();
f010088a:	e8 ae fa ff ff       	call   f010033d <cga_init>
	kbd_init();
f010088f:	e8 24 ff ff ff       	call   f01007b8 <kbd_init>
	serial_init();
f0100894:	e8 15 f9 ff ff       	call   f01001ae <serial_init>

	if (!serial_exists)
f0100899:	a1 c0 75 11 f0       	mov    0xf01175c0,%eax
f010089e:	85 c0                	test   %eax,%eax
f01008a0:	75 0c                	jne    f01008ae <cons_init+0x2a>
		cprintf("Serial port does not exist!\n");
f01008a2:	c7 04 24 33 49 10 f0 	movl   $0xf0104933,(%esp)
f01008a9:	e8 5a 2c 00 00       	call   f0103508 <cprintf>
}
f01008ae:	c9                   	leave  
f01008af:	c3                   	ret    

f01008b0 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01008b0:	55                   	push   %ebp
f01008b1:	89 e5                	mov    %esp,%ebp
f01008b3:	83 ec 18             	sub    $0x18,%esp
	cons_putc(c);
f01008b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01008b9:	89 04 24             	mov    %eax,(%esp)
f01008bc:	e8 a5 ff ff ff       	call   f0100866 <cons_putc>
}
f01008c1:	c9                   	leave  
f01008c2:	c3                   	ret    

f01008c3 <getchar>:

int
getchar(void)
{
f01008c3:	55                   	push   %ebp
f01008c4:	89 e5                	mov    %esp,%ebp
f01008c6:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01008c9:	e8 3c ff ff ff       	call   f010080a <cons_getc>
f01008ce:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01008d1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f01008d5:	74 f2                	je     f01008c9 <getchar+0x6>
		/* do nothing */;
	return c;
f01008d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f01008da:	c9                   	leave  
f01008db:	c3                   	ret    

f01008dc <iscons>:

int
iscons(int fdnum)
{
f01008dc:	55                   	push   %ebp
f01008dd:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
f01008df:	b8 01 00 00 00       	mov    $0x1,%eax
}
f01008e4:	5d                   	pop    %ebp
f01008e5:	c3                   	ret    

f01008e6 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01008e6:	55                   	push   %ebp
f01008e7:	89 e5                	mov    %esp,%ebp
f01008e9:	83 ec 28             	sub    $0x28,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f01008ec:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f01008f3:	eb 3e                	jmp    f0100933 <mon_help+0x4d>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01008f5:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01008f8:	89 d0                	mov    %edx,%eax
f01008fa:	01 c0                	add    %eax,%eax
f01008fc:	01 d0                	add    %edx,%eax
f01008fe:	c1 e0 02             	shl    $0x2,%eax
f0100901:	05 34 75 11 f0       	add    $0xf0117534,%eax
f0100906:	8b 08                	mov    (%eax),%ecx
f0100908:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010090b:	89 d0                	mov    %edx,%eax
f010090d:	01 c0                	add    %eax,%eax
f010090f:	01 d0                	add    %edx,%eax
f0100911:	c1 e0 02             	shl    $0x2,%eax
f0100914:	05 30 75 11 f0       	add    $0xf0117530,%eax
f0100919:	8b 00                	mov    (%eax),%eax
f010091b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010091f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100923:	c7 04 24 a1 49 10 f0 	movl   $0xf01049a1,(%esp)
f010092a:	e8 d9 2b 00 00       	call   f0103508 <cprintf>
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f010092f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
f0100933:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100936:	83 f8 01             	cmp    $0x1,%eax
f0100939:	76 ba                	jbe    f01008f5 <mon_help+0xf>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
f010093b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100940:	c9                   	leave  
f0100941:	c3                   	ret    

f0100942 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100942:	55                   	push   %ebp
f0100943:	89 e5                	mov    %esp,%ebp
f0100945:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100948:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f010094f:	e8 b4 2b 00 00       	call   f0103508 <cprintf>
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
f0100954:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010095b:	00 
f010095c:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100963:	f0 
f0100964:	c7 04 24 c4 49 10 f0 	movl   $0xf01049c4,(%esp)
f010096b:	e8 98 2b 00 00       	call   f0103508 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100970:	c7 44 24 08 d7 48 10 	movl   $0x1048d7,0x8(%esp)
f0100977:	00 
f0100978:	c7 44 24 04 d7 48 10 	movl   $0xf01048d7,0x4(%esp)
f010097f:	f0 
f0100980:	c7 04 24 e8 49 10 f0 	movl   $0xf01049e8,(%esp)
f0100987:	e8 7c 2b 00 00       	call   f0103508 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010098c:	c7 44 24 08 96 75 11 	movl   $0x117596,0x8(%esp)
f0100993:	00 
f0100994:	c7 44 24 04 96 75 11 	movl   $0xf0117596,0x4(%esp)
f010099b:	f0 
f010099c:	c7 04 24 0c 4a 10 f0 	movl   $0xf0104a0c,(%esp)
f01009a3:	e8 60 2b 00 00       	call   f0103508 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01009a8:	c7 44 24 08 30 7c 11 	movl   $0x117c30,0x8(%esp)
f01009af:	00 
f01009b0:	c7 44 24 04 30 7c 11 	movl   $0xf0117c30,0x4(%esp)
f01009b7:	f0 
f01009b8:	c7 04 24 30 4a 10 f0 	movl   $0xf0104a30,(%esp)
f01009bf:	e8 44 2b 00 00       	call   f0103508 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-_start+1023)/1024);
f01009c4:	b8 30 7c 11 f0       	mov    $0xf0117c30,%eax
f01009c9:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01009cf:	b8 0c 00 10 f0       	mov    $0xf010000c,%eax
f01009d4:	29 c2                	sub    %eax,%edx
f01009d6:	89 d0                	mov    %edx,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01009d8:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01009de:	85 c0                	test   %eax,%eax
f01009e0:	0f 48 c2             	cmovs  %edx,%eax
f01009e3:	c1 f8 0a             	sar    $0xa,%eax
f01009e6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009ea:	c7 04 24 54 4a 10 f0 	movl   $0xf0104a54,(%esp)
f01009f1:	e8 12 2b 00 00       	call   f0103508 <cprintf>
		(end-_start+1023)/1024);
	return 0;
f01009f6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01009fb:	c9                   	leave  
f01009fc:	c3                   	ret    

f01009fd <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01009fd:	55                   	push   %ebp
f01009fe:	89 e5                	mov    %esp,%ebp
f0100a00:	53                   	push   %ebx
f0100a01:	81 ec 94 00 00 00    	sub    $0x94,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100a07:	89 e8                	mov    %ebp,%eax
f0100a09:	89 45 ec             	mov    %eax,-0x14(%ebp)
        return ebp;
f0100a0c:	8b 45 ec             	mov    -0x14(%ebp),%eax
	// Your code here.
//	cprintf("ebp %x eip %x args %x %x %x %x %x\n",read_ebp(),*(int *)(read_ebp()-4),argc,argv,tf,*(&tf-4),*(&tf-8));
	unsigned int x=read_ebp();
f0100a0f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	struct Eipdebuginfo debug_info;
	unsigned int eip;
	char func_name[64];
	while (x>0)
f0100a12:	e9 bb 00 00 00       	jmp    f0100ad2 <mon_backtrace+0xd5>
	{
		eip=*(unsigned int *)(x+4);
f0100a17:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a1a:	83 c0 04             	add    $0x4,%eax
f0100a1d:	8b 00                	mov    (%eax),%eax
f0100a1f:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if (debuginfo_eip(eip,&debug_info)>=0)
f0100a22:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f0100a25:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a29:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a2c:	89 04 24             	mov    %eax,(%esp)
f0100a2f:	e8 50 2c 00 00       	call   f0103684 <debuginfo_eip>
f0100a34:	85 c0                	test   %eax,%eax
f0100a36:	0f 88 8e 00 00 00    	js     f0100aca <mon_backtrace+0xcd>
		{
			strncpy(func_name,debug_info.eip_fn_name,debug_info.eip_fn_namelen);
f0100a3c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a3f:	89 c2                	mov    %eax,%edx
f0100a41:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100a44:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100a48:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a4c:	8d 45 94             	lea    -0x6c(%ebp),%eax
f0100a4f:	89 04 24             	mov    %eax,(%esp)
f0100a52:	e8 aa 37 00 00       	call   f0104201 <strncpy>
			func_name[debug_info.eip_fn_namelen]=0;
f0100a57:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a5a:	c6 44 05 94 00       	movb   $0x0,-0x6c(%ebp,%eax,1)
			cprintf("%s:%d: %s+%x\n",debug_info.eip_file,debug_info.eip_line,func_name,debug_info.eip_fn_addr);
f0100a5f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a62:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100a65:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100a68:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100a6c:	8d 4d 94             	lea    -0x6c(%ebp),%ecx
f0100a6f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100a73:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100a77:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a7b:	c7 04 24 7e 4a 10 f0 	movl   $0xf0104a7e,(%esp)
f0100a82:	e8 81 2a 00 00       	call   f0103508 <cprintf>
			cprintf("\tebp %x eip %x args %x %x %x %x %x\n",x,*(unsigned int *)(x+4),*(unsigned int *)(x+8),*(unsigned int *)(x+12),*(unsigned int *)(x+16));
f0100a87:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a8a:	83 c0 10             	add    $0x10,%eax
f0100a8d:	8b 18                	mov    (%eax),%ebx
f0100a8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a92:	83 c0 0c             	add    $0xc,%eax
f0100a95:	8b 08                	mov    (%eax),%ecx
f0100a97:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a9a:	83 c0 08             	add    $0x8,%eax
f0100a9d:	8b 10                	mov    (%eax),%edx
f0100a9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100aa2:	83 c0 04             	add    $0x4,%eax
f0100aa5:	8b 00                	mov    (%eax),%eax
f0100aa7:	89 5c 24 14          	mov    %ebx,0x14(%esp)
f0100aab:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100aaf:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100ab3:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ab7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100aba:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100abe:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0100ac5:	e8 3e 2a 00 00       	call   f0103508 <cprintf>
		}
		x=*(unsigned int*)(x);
f0100aca:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100acd:	8b 00                	mov    (%eax),%eax
f0100acf:	89 45 f4             	mov    %eax,-0xc(%ebp)
//	cprintf("ebp %x eip %x args %x %x %x %x %x\n",read_ebp(),*(int *)(read_ebp()-4),argc,argv,tf,*(&tf-4),*(&tf-8));
	unsigned int x=read_ebp();
	struct Eipdebuginfo debug_info;
	unsigned int eip;
	char func_name[64];
	while (x>0)
f0100ad2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100ad6:	0f 85 3b ff ff ff    	jne    f0100a17 <mon_backtrace+0x1a>
		}
		x=*(unsigned int*)(x);
	}

	
	return 0;
f0100adc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100ae1:	81 c4 94 00 00 00    	add    $0x94,%esp
f0100ae7:	5b                   	pop    %ebx
f0100ae8:	5d                   	pop    %ebp
f0100ae9:	c3                   	ret    

f0100aea <runcmd>:
#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
f0100aea:	55                   	push   %ebp
f0100aeb:	89 e5                	mov    %esp,%ebp
f0100aed:	83 ec 68             	sub    $0x68,%esp
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100af0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	argv[argc] = 0;
f0100af7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100afa:	c7 44 85 b0 00 00 00 	movl   $0x0,-0x50(%ebp,%eax,4)
f0100b01:	00 
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100b02:	eb 0c                	jmp    f0100b10 <runcmd+0x26>
			*buf++ = 0;
f0100b04:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b07:	8d 50 01             	lea    0x1(%eax),%edx
f0100b0a:	89 55 08             	mov    %edx,0x8(%ebp)
f0100b0d:	c6 00 00             	movb   $0x0,(%eax)
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100b10:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b13:	0f b6 00             	movzbl (%eax),%eax
f0100b16:	84 c0                	test   %al,%al
f0100b18:	74 1d                	je     f0100b37 <runcmd+0x4d>
f0100b1a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b1d:	0f b6 00             	movzbl (%eax),%eax
f0100b20:	0f be c0             	movsbl %al,%eax
f0100b23:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b27:	c7 04 24 b0 4a 10 f0 	movl   $0xf0104ab0,(%esp)
f0100b2e:	e8 f9 37 00 00       	call   f010432c <strchr>
f0100b33:	85 c0                	test   %eax,%eax
f0100b35:	75 cd                	jne    f0100b04 <runcmd+0x1a>
			*buf++ = 0;
		if (*buf == 0)
f0100b37:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b3a:	0f b6 00             	movzbl (%eax),%eax
f0100b3d:	84 c0                	test   %al,%al
f0100b3f:	75 14                	jne    f0100b55 <runcmd+0x6b>
			break;
f0100b41:	90                   	nop
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;
f0100b42:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b45:	c7 44 85 b0 00 00 00 	movl   $0x0,-0x50(%ebp,%eax,4)
f0100b4c:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100b4d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100b51:	75 70                	jne    f0100bc3 <runcmd+0xd9>
f0100b53:	eb 67                	jmp    f0100bbc <runcmd+0xd2>
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100b55:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
f0100b59:	75 1e                	jne    f0100b79 <runcmd+0x8f>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100b5b:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100b62:	00 
f0100b63:	c7 04 24 b5 4a 10 f0 	movl   $0xf0104ab5,(%esp)
f0100b6a:	e8 99 29 00 00       	call   f0103508 <cprintf>
			return 0;
f0100b6f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b74:	e9 c8 00 00 00       	jmp    f0100c41 <runcmd+0x157>
		}
		argv[argc++] = buf;
f0100b79:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b7c:	8d 50 01             	lea    0x1(%eax),%edx
f0100b7f:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0100b82:	8b 55 08             	mov    0x8(%ebp),%edx
f0100b85:	89 54 85 b0          	mov    %edx,-0x50(%ebp,%eax,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100b89:	eb 04                	jmp    f0100b8f <runcmd+0xa5>
			buf++;
f0100b8b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100b8f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b92:	0f b6 00             	movzbl (%eax),%eax
f0100b95:	84 c0                	test   %al,%al
f0100b97:	74 1d                	je     f0100bb6 <runcmd+0xcc>
f0100b99:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b9c:	0f b6 00             	movzbl (%eax),%eax
f0100b9f:	0f be c0             	movsbl %al,%eax
f0100ba2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ba6:	c7 04 24 b0 4a 10 f0 	movl   $0xf0104ab0,(%esp)
f0100bad:	e8 7a 37 00 00       	call   f010432c <strchr>
f0100bb2:	85 c0                	test   %eax,%eax
f0100bb4:	74 d5                	je     f0100b8b <runcmd+0xa1>
			buf++;
	}
f0100bb6:	90                   	nop
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100bb7:	e9 54 ff ff ff       	jmp    f0100b10 <runcmd+0x26>
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
f0100bbc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bc1:	eb 7e                	jmp    f0100c41 <runcmd+0x157>
	for (i = 0; i < NCOMMANDS; i++) {
f0100bc3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f0100bca:	eb 55                	jmp    f0100c21 <runcmd+0x137>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100bcc:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100bcf:	89 d0                	mov    %edx,%eax
f0100bd1:	01 c0                	add    %eax,%eax
f0100bd3:	01 d0                	add    %edx,%eax
f0100bd5:	c1 e0 02             	shl    $0x2,%eax
f0100bd8:	05 30 75 11 f0       	add    $0xf0117530,%eax
f0100bdd:	8b 10                	mov    (%eax),%edx
f0100bdf:	8b 45 b0             	mov    -0x50(%ebp),%eax
f0100be2:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100be6:	89 04 24             	mov    %eax,(%esp)
f0100be9:	e8 a9 36 00 00       	call   f0104297 <strcmp>
f0100bee:	85 c0                	test   %eax,%eax
f0100bf0:	75 2b                	jne    f0100c1d <runcmd+0x133>
			return commands[i].func(argc, argv, tf);
f0100bf2:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100bf5:	89 d0                	mov    %edx,%eax
f0100bf7:	01 c0                	add    %eax,%eax
f0100bf9:	01 d0                	add    %edx,%eax
f0100bfb:	c1 e0 02             	shl    $0x2,%eax
f0100bfe:	05 38 75 11 f0       	add    $0xf0117538,%eax
f0100c03:	8b 00                	mov    (%eax),%eax
f0100c05:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100c08:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100c0c:	8d 55 b0             	lea    -0x50(%ebp),%edx
f0100c0f:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100c13:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100c16:	89 14 24             	mov    %edx,(%esp)
f0100c19:	ff d0                	call   *%eax
f0100c1b:	eb 24                	jmp    f0100c41 <runcmd+0x157>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100c1d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
f0100c21:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100c24:	83 f8 01             	cmp    $0x1,%eax
f0100c27:	76 a3                	jbe    f0100bcc <runcmd+0xe2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100c29:	8b 45 b0             	mov    -0x50(%ebp),%eax
f0100c2c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c30:	c7 04 24 d2 4a 10 f0 	movl   $0xf0104ad2,(%esp)
f0100c37:	e8 cc 28 00 00       	call   f0103508 <cprintf>
	return 0;
f0100c3c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c41:	c9                   	leave  
f0100c42:	c3                   	ret    

f0100c43 <monitor>:

void
monitor(struct Trapframe *tf)
{
f0100c43:	55                   	push   %ebp
f0100c44:	89 e5                	mov    %esp,%ebp
f0100c46:	83 ec 28             	sub    $0x28,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100c49:	c7 04 24 e8 4a 10 f0 	movl   $0xf0104ae8,(%esp)
f0100c50:	e8 b3 28 00 00       	call   f0103508 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100c55:	c7 04 24 0c 4b 10 f0 	movl   $0xf0104b0c,(%esp)
f0100c5c:	e8 a7 28 00 00       	call   f0103508 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100c61:	c7 04 24 31 4b 10 f0 	movl   $0xf0104b31,(%esp)
f0100c68:	e8 21 34 00 00       	call   f010408e <readline>
f0100c6d:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if (buf != NULL)
f0100c70:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100c74:	74 18                	je     f0100c8e <monitor+0x4b>
			if (runcmd(buf, tf) < 0)
f0100c76:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c79:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100c80:	89 04 24             	mov    %eax,(%esp)
f0100c83:	e8 62 fe ff ff       	call   f0100aea <runcmd>
f0100c88:	85 c0                	test   %eax,%eax
f0100c8a:	79 02                	jns    f0100c8e <monitor+0x4b>
				break;
f0100c8c:	eb 02                	jmp    f0100c90 <monitor+0x4d>
	}
f0100c8e:	eb d1                	jmp    f0100c61 <monitor+0x1e>
}
f0100c90:	c9                   	leave  
f0100c91:	c3                   	ret    

f0100c92 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100c92:	55                   	push   %ebp
f0100c93:	89 e5                	mov    %esp,%ebp
f0100c95:	83 ec 10             	sub    $0x10,%esp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100c98:	8b 45 04             	mov    0x4(%ebp),%eax
f0100c9b:	89 45 fc             	mov    %eax,-0x4(%ebp)
	return callerpc;
f0100c9e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0100ca1:	c9                   	leave  
f0100ca2:	c3                   	ret    

f0100ca3 <page2ppn>:

void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
f0100ca3:	55                   	push   %ebp
f0100ca4:	89 e5                	mov    %esp,%ebp
	return pp - pages;
f0100ca6:	8b 55 08             	mov    0x8(%ebp),%edx
f0100ca9:	a1 2c 7c 11 f0       	mov    0xf0117c2c,%eax
f0100cae:	29 c2                	sub    %eax,%edx
f0100cb0:	89 d0                	mov    %edx,%eax
f0100cb2:	c1 f8 02             	sar    $0x2,%eax
f0100cb5:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}
f0100cbb:	5d                   	pop    %ebp
f0100cbc:	c3                   	ret    

f0100cbd <page2pa>:

static inline physaddr_t
page2pa(struct Page *pp)
{
f0100cbd:	55                   	push   %ebp
f0100cbe:	89 e5                	mov    %esp,%ebp
f0100cc0:	83 ec 04             	sub    $0x4,%esp
	return page2ppn(pp) << PGSHIFT;
f0100cc3:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cc6:	89 04 24             	mov    %eax,(%esp)
f0100cc9:	e8 d5 ff ff ff       	call   f0100ca3 <page2ppn>
f0100cce:	c1 e0 0c             	shl    $0xc,%eax
}
f0100cd1:	c9                   	leave  
f0100cd2:	c3                   	ret    

f0100cd3 <pa2page>:

static inline struct Page*
pa2page(physaddr_t pa)
{
f0100cd3:	55                   	push   %ebp
f0100cd4:	89 e5                	mov    %esp,%ebp
f0100cd6:	83 ec 18             	sub    $0x18,%esp
	if (PPN(pa) >= npage)
f0100cd9:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cdc:	c1 e8 0c             	shr    $0xc,%eax
f0100cdf:	89 c2                	mov    %eax,%edx
f0100ce1:	a1 20 7c 11 f0       	mov    0xf0117c20,%eax
f0100ce6:	39 c2                	cmp    %eax,%edx
f0100ce8:	72 1c                	jb     f0100d06 <pa2page+0x33>
		panic("pa2page called with invalid pa");
f0100cea:	c7 44 24 08 38 4b 10 	movl   $0xf0104b38,0x8(%esp)
f0100cf1:	f0 
f0100cf2:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0100cf9:	00 
f0100cfa:	c7 04 24 57 4b 10 f0 	movl   $0xf0104b57,(%esp)
f0100d01:	e8 96 f3 ff ff       	call   f010009c <_panic>
	return &pages[PPN(pa)];
f0100d06:	8b 0d 2c 7c 11 f0    	mov    0xf0117c2c,%ecx
f0100d0c:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d0f:	c1 e8 0c             	shr    $0xc,%eax
f0100d12:	89 c2                	mov    %eax,%edx
f0100d14:	89 d0                	mov    %edx,%eax
f0100d16:	01 c0                	add    %eax,%eax
f0100d18:	01 d0                	add    %edx,%eax
f0100d1a:	c1 e0 02             	shl    $0x2,%eax
f0100d1d:	01 c8                	add    %ecx,%eax
}
f0100d1f:	c9                   	leave  
f0100d20:	c3                   	ret    

f0100d21 <page2kva>:

static inline void*
page2kva(struct Page *pp)
{
f0100d21:	55                   	push   %ebp
f0100d22:	89 e5                	mov    %esp,%ebp
f0100d24:	83 ec 28             	sub    $0x28,%esp
	return KADDR(page2pa(pp));
f0100d27:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d2a:	89 04 24             	mov    %eax,(%esp)
f0100d2d:	e8 8b ff ff ff       	call   f0100cbd <page2pa>
f0100d32:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100d35:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100d38:	c1 e8 0c             	shr    $0xc,%eax
f0100d3b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100d3e:	a1 20 7c 11 f0       	mov    0xf0117c20,%eax
f0100d43:	39 45 f0             	cmp    %eax,-0x10(%ebp)
f0100d46:	72 23                	jb     f0100d6b <page2kva+0x4a>
f0100d48:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100d4b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d4f:	c7 44 24 08 68 4b 10 	movl   $0xf0104b68,0x8(%esp)
f0100d56:	f0 
f0100d57:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100d5e:	00 
f0100d5f:	c7 04 24 57 4b 10 f0 	movl   $0xf0104b57,(%esp)
f0100d66:	e8 31 f3 ff ff       	call   f010009c <_panic>
f0100d6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100d6e:	2d 00 00 00 10       	sub    $0x10000000,%eax
}
f0100d73:	c9                   	leave  
f0100d74:	c3                   	ret    

f0100d75 <nvram_read>:
	sizeof(gdt) - 1, (unsigned long) gdt
};

static int
nvram_read(int r)
{
f0100d75:	55                   	push   %ebp
f0100d76:	89 e5                	mov    %esp,%ebp
f0100d78:	53                   	push   %ebx
f0100d79:	83 ec 14             	sub    $0x14,%esp
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100d7c:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d7f:	89 04 24             	mov    %eax,(%esp)
f0100d82:	e8 c3 26 00 00       	call   f010344a <mc146818_read>
f0100d87:	89 c3                	mov    %eax,%ebx
f0100d89:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d8c:	83 c0 01             	add    $0x1,%eax
f0100d8f:	89 04 24             	mov    %eax,(%esp)
f0100d92:	e8 b3 26 00 00       	call   f010344a <mc146818_read>
f0100d97:	c1 e0 08             	shl    $0x8,%eax
f0100d9a:	09 d8                	or     %ebx,%eax
}
f0100d9c:	83 c4 14             	add    $0x14,%esp
f0100d9f:	5b                   	pop    %ebx
f0100da0:	5d                   	pop    %ebp
f0100da1:	c3                   	ret    

f0100da2 <i386_detect_memory>:

void
i386_detect_memory(void)
{
f0100da2:	55                   	push   %ebp
f0100da3:	89 e5                	mov    %esp,%ebp
f0100da5:	83 ec 28             	sub    $0x28,%esp
	// CMOS tells us how many kilobytes there are
	basemem = ROUNDDOWN(nvram_read(NVRAM_BASELO)*1024, PGSIZE);
f0100da8:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f0100daf:	e8 c1 ff ff ff       	call   f0100d75 <nvram_read>
f0100db4:	c1 e0 0a             	shl    $0xa,%eax
f0100db7:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100dba:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100dbd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100dc2:	a3 f0 77 11 f0       	mov    %eax,0xf01177f0
	extmem = ROUNDDOWN(nvram_read(NVRAM_EXTLO)*1024, PGSIZE);
f0100dc7:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0100dce:	e8 a2 ff ff ff       	call   f0100d75 <nvram_read>
f0100dd3:	c1 e0 0a             	shl    $0xa,%eax
f0100dd6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100dd9:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100ddc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100de1:	a3 f4 77 11 f0       	mov    %eax,0xf01177f4

	// Calculate the maximum physical address based on whether
	// or not there is any extended memory.  See comment in <inc/mmu.h>.
	if (extmem)
f0100de6:	a1 f4 77 11 f0       	mov    0xf01177f4,%eax
f0100deb:	85 c0                	test   %eax,%eax
f0100ded:	74 11                	je     f0100e00 <i386_detect_memory+0x5e>
		maxpa = EXTPHYSMEM + extmem;
f0100def:	a1 f4 77 11 f0       	mov    0xf01177f4,%eax
f0100df4:	05 00 00 10 00       	add    $0x100000,%eax
f0100df9:	a3 ec 77 11 f0       	mov    %eax,0xf01177ec
f0100dfe:	eb 0a                	jmp    f0100e0a <i386_detect_memory+0x68>
	else
		maxpa = basemem;
f0100e00:	a1 f0 77 11 f0       	mov    0xf01177f0,%eax
f0100e05:	a3 ec 77 11 f0       	mov    %eax,0xf01177ec

	npage = maxpa / PGSIZE;
f0100e0a:	a1 ec 77 11 f0       	mov    0xf01177ec,%eax
f0100e0f:	c1 e8 0c             	shr    $0xc,%eax
f0100e12:	a3 20 7c 11 f0       	mov    %eax,0xf0117c20

	cprintf("Physical memory: %dK available, ", (int)(maxpa/1024));
f0100e17:	a1 ec 77 11 f0       	mov    0xf01177ec,%eax
f0100e1c:	c1 e8 0a             	shr    $0xa,%eax
f0100e1f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e23:	c7 04 24 8c 4b 10 f0 	movl   $0xf0104b8c,(%esp)
f0100e2a:	e8 d9 26 00 00       	call   f0103508 <cprintf>
	cprintf("base = %dK, extended = %dK\n", (int)(basemem/1024), (int)(extmem/1024));
f0100e2f:	a1 f4 77 11 f0       	mov    0xf01177f4,%eax
f0100e34:	c1 e8 0a             	shr    $0xa,%eax
f0100e37:	89 c2                	mov    %eax,%edx
f0100e39:	a1 f0 77 11 f0       	mov    0xf01177f0,%eax
f0100e3e:	c1 e8 0a             	shr    $0xa,%eax
f0100e41:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100e45:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e49:	c7 04 24 ad 4b 10 f0 	movl   $0xf0104bad,(%esp)
f0100e50:	e8 b3 26 00 00       	call   f0103508 <cprintf>
}
f0100e55:	c9                   	leave  
f0100e56:	c3                   	ret    

f0100e57 <boot_alloc>:
// This function may ONLY be used during initialization,
// before the page_free_list has been set up.
// 
static void*
boot_alloc(uint32_t n, uint32_t align)
{
f0100e57:	55                   	push   %ebp
f0100e58:	89 e5                	mov    %esp,%ebp
f0100e5a:	83 ec 10             	sub    $0x10,%esp
	// Initialize boot_freemem if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment -
	// i.e., the first virtual address that the linker
	// did _not_ assign to any kernel code or global variables.
	if (boot_freemem == 0)
f0100e5d:	a1 f8 77 11 f0       	mov    0xf01177f8,%eax
f0100e62:	85 c0                	test   %eax,%eax
f0100e64:	75 0a                	jne    f0100e70 <boot_alloc+0x19>
		boot_freemem = end;
f0100e66:	c7 05 f8 77 11 f0 30 	movl   $0xf0117c30,0xf01177f8
f0100e6d:	7c 11 f0 

	// LAB 2: Your code here:
	//	Step 1: round boot_freemem up to be aligned properly
	boot_freemem=ROUNDUP(boot_freemem,align);
f0100e70:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e73:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0100e76:	a1 f8 77 11 f0       	mov    0xf01177f8,%eax
f0100e7b:	89 c2                	mov    %eax,%edx
f0100e7d:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100e80:	01 d0                	add    %edx,%eax
f0100e82:	83 e8 01             	sub    $0x1,%eax
f0100e85:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0100e88:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0100e8b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e90:	f7 75 fc             	divl   -0x4(%ebp)
f0100e93:	89 d0                	mov    %edx,%eax
f0100e95:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0100e98:	29 c2                	sub    %eax,%edx
f0100e9a:	89 d0                	mov    %edx,%eax
f0100e9c:	a3 f8 77 11 f0       	mov    %eax,0xf01177f8
	//	Step 2: save current value of boot_freemem as allocated chunk
	v=boot_freemem;
f0100ea1:	a1 f8 77 11 f0       	mov    0xf01177f8,%eax
f0100ea6:	89 45 f4             	mov    %eax,-0xc(%ebp)
	//	Step 3: increase boot_freemem to record allocation
	boot_freemem+=n;
f0100ea9:	8b 15 f8 77 11 f0    	mov    0xf01177f8,%edx
f0100eaf:	8b 45 08             	mov    0x8(%ebp),%eax
f0100eb2:	01 d0                	add    %edx,%eax
f0100eb4:	a3 f8 77 11 f0       	mov    %eax,0xf01177f8
	//	Step 4: return allocated chunk
	
	return v;
f0100eb9:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0100ebc:	c9                   	leave  
f0100ebd:	c3                   	ret    

f0100ebe <i386_vm_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read (or write). 
void
i386_vm_init(void)
{
f0100ebe:	55                   	push   %ebp
f0100ebf:	89 e5                	mov    %esp,%ebp
f0100ec1:	83 ec 68             	sub    $0x68,%esp
	// Delete this line:
	//panic("i386_vm_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	pgdir = boot_alloc(PGSIZE, PGSIZE);
f0100ec4:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0100ecb:	00 
f0100ecc:	c7 04 24 00 10 00 00 	movl   $0x1000,(%esp)
f0100ed3:	e8 7f ff ff ff       	call   f0100e57 <boot_alloc>
f0100ed8:	89 45 f4             	mov    %eax,-0xc(%ebp)
	memset(pgdir, 0, PGSIZE);
f0100edb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100ee2:	00 
f0100ee3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100eea:	00 
f0100eeb:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100eee:	89 04 24             	mov    %eax,(%esp)
f0100ef1:	e8 97 34 00 00       	call   f010438d <memset>
	boot_pgdir = pgdir;
f0100ef6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100ef9:	a3 28 7c 11 f0       	mov    %eax,0xf0117c28
	boot_cr3 = PADDR(pgdir);
f0100efe:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f01:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100f04:	81 7d f0 ff ff ff ef 	cmpl   $0xefffffff,-0x10(%ebp)
f0100f0b:	77 23                	ja     f0100f30 <i386_vm_init+0x72>
f0100f0d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f10:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f14:	c7 44 24 08 cc 4b 10 	movl   $0xf0104bcc,0x8(%esp)
f0100f1b:	f0 
f0100f1c:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
f0100f23:	00 
f0100f24:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0100f2b:	e8 6c f1 ff ff       	call   f010009c <_panic>
f0100f30:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f33:	05 00 00 00 10       	add    $0x10000000,%eax
f0100f38:	a3 24 7c 11 f0       	mov    %eax,0xf0117c24
	// a virtual page table at virtual address VPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel RW, user NONE
	pgdir[PDX(VPT)] = PADDR(pgdir)|PTE_W|PTE_P;
f0100f3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f40:	8d 90 fc 0e 00 00    	lea    0xefc(%eax),%edx
f0100f46:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f49:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100f4c:	81 7d ec ff ff ff ef 	cmpl   $0xefffffff,-0x14(%ebp)
f0100f53:	77 23                	ja     f0100f78 <i386_vm_init+0xba>
f0100f55:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100f58:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f5c:	c7 44 24 08 cc 4b 10 	movl   $0xf0104bcc,0x8(%esp)
f0100f63:	f0 
f0100f64:	c7 44 24 04 a7 00 00 	movl   $0xa7,0x4(%esp)
f0100f6b:	00 
f0100f6c:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0100f73:	e8 24 f1 ff ff       	call   f010009c <_panic>
f0100f78:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100f7b:	05 00 00 00 10       	add    $0x10000000,%eax
f0100f80:	83 c8 03             	or     $0x3,%eax
f0100f83:	89 02                	mov    %eax,(%edx)

	// same for UVPT
	// Permissions: kernel R, user R 
	pgdir[PDX(UVPT)] = PADDR(pgdir)|PTE_U|PTE_P;
f0100f85:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f88:	8d 90 f4 0e 00 00    	lea    0xef4(%eax),%edx
f0100f8e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f91:	89 45 e8             	mov    %eax,-0x18(%ebp)
f0100f94:	81 7d e8 ff ff ff ef 	cmpl   $0xefffffff,-0x18(%ebp)
f0100f9b:	77 23                	ja     f0100fc0 <i386_vm_init+0x102>
f0100f9d:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100fa0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fa4:	c7 44 24 08 cc 4b 10 	movl   $0xf0104bcc,0x8(%esp)
f0100fab:	f0 
f0100fac:	c7 44 24 04 ab 00 00 	movl   $0xab,0x4(%esp)
f0100fb3:	00 
f0100fb4:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0100fbb:	e8 dc f0 ff ff       	call   f010009c <_panic>
f0100fc0:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100fc3:	05 00 00 00 10       	add    $0x10000000,%eax
f0100fc8:	83 c8 05             	or     $0x5,%eax
f0100fcb:	89 02                	mov    %eax,(%edx)
	// The kernel uses this structure to keep track of physical pages;
	// 'npage' equals the number of physical pages in memory.  User-level
	// programs will get read-only access to the array as well.
	// You must allocate the array yourself.
	// Your code goes here: 
	pages=boot_alloc(npage*sizeof(struct Page),PGSIZE);
f0100fcd:	8b 15 20 7c 11 f0    	mov    0xf0117c20,%edx
f0100fd3:	89 d0                	mov    %edx,%eax
f0100fd5:	01 c0                	add    %eax,%eax
f0100fd7:	01 d0                	add    %edx,%eax
f0100fd9:	c1 e0 02             	shl    $0x2,%eax
f0100fdc:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0100fe3:	00 
f0100fe4:	89 04 24             	mov    %eax,(%esp)
f0100fe7:	e8 6b fe ff ff       	call   f0100e57 <boot_alloc>
f0100fec:	a3 2c 7c 11 f0       	mov    %eax,0xf0117c2c
	//////////////////////////////////////////////////////////////////////
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_segment or page_insert
	page_init();
f0100ff1:	e8 b6 09 00 00       	call   f01019ac <page_init>

    check_page_alloc();
f0100ff6:	e8 c4 01 00 00       	call   f01011bf <check_page_alloc>
	//cprintf("---------------------------->haha\n");
	page_check();
f0100ffb:	e8 be 11 00 00       	call   f01021be <page_check>
	// (ie. perm = PTE_U | PTE_P)
	// Permissions:
	//    - pages -- kernel RW, user NONE
	//    - the read-only version mapped at UPAGES -- kernel R, user R
	// Your code goes here:
	n=ROUNDUP(sizeof(struct Page)*npage,PGSIZE);
f0101000:	c7 45 e4 00 10 00 00 	movl   $0x1000,-0x1c(%ebp)
f0101007:	8b 15 20 7c 11 f0    	mov    0xf0117c20,%edx
f010100d:	89 d0                	mov    %edx,%eax
f010100f:	01 c0                	add    %eax,%eax
f0101011:	01 d0                	add    %edx,%eax
f0101013:	c1 e0 02             	shl    $0x2,%eax
f0101016:	89 c2                	mov    %eax,%edx
f0101018:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010101b:	01 d0                	add    %edx,%eax
f010101d:	83 e8 01             	sub    $0x1,%eax
f0101020:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101023:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101026:	ba 00 00 00 00       	mov    $0x0,%edx
f010102b:	f7 75 e4             	divl   -0x1c(%ebp)
f010102e:	89 d0                	mov    %edx,%eax
f0101030:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101033:	29 c2                	sub    %eax,%edx
f0101035:	89 d0                	mov    %edx,%eax
f0101037:	89 45 dc             	mov    %eax,-0x24(%ebp)
	boot_map_segment(pgdir,UPAGES,n,PADDR(pages),PTE_U | PTE_P);
f010103a:	a1 2c 7c 11 f0       	mov    0xf0117c2c,%eax
f010103f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101042:	81 7d d8 ff ff ff ef 	cmpl   $0xefffffff,-0x28(%ebp)
f0101049:	77 23                	ja     f010106e <i386_vm_init+0x1b0>
f010104b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010104e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101052:	c7 44 24 08 cc 4b 10 	movl   $0xf0104bcc,0x8(%esp)
f0101059:	f0 
f010105a:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
f0101061:	00 
f0101062:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0101069:	e8 2e f0 ff ff       	call   f010009c <_panic>
f010106e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101071:	05 00 00 00 10       	add    $0x10000000,%eax
f0101076:	c7 44 24 10 05 00 00 	movl   $0x5,0x10(%esp)
f010107d:	00 
f010107e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101082:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101085:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101089:	c7 44 24 04 00 00 00 	movl   $0xef000000,0x4(%esp)
f0101090:	ef 
f0101091:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101094:	89 04 24             	mov    %eax,(%esp)
f0101097:	e8 b6 0f 00 00       	call   f0102052 <boot_map_segment>
	// pieces:
	//     * [KSTACKTOP-KSTKSIZE, KSTACKTOP) -- backed by physical memory
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed => faults
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_segment(pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_P|PTE_W);
f010109c:	c7 45 d4 00 f0 10 f0 	movl   $0xf010f000,-0x2c(%ebp)
f01010a3:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01010aa:	77 23                	ja     f01010cf <i386_vm_init+0x211>
f01010ac:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01010af:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01010b3:	c7 44 24 08 cc 4b 10 	movl   $0xf0104bcc,0x8(%esp)
f01010ba:	f0 
f01010bb:	c7 44 24 04 d7 00 00 	movl   $0xd7,0x4(%esp)
f01010c2:	00 
f01010c3:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01010ca:	e8 cd ef ff ff       	call   f010009c <_panic>
f01010cf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01010d2:	05 00 00 00 10       	add    $0x10000000,%eax
f01010d7:	c7 44 24 10 03 00 00 	movl   $0x3,0x10(%esp)
f01010de:	00 
f01010df:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01010e3:	c7 44 24 08 00 80 00 	movl   $0x8000,0x8(%esp)
f01010ea:	00 
f01010eb:	c7 44 24 04 00 80 bf 	movl   $0xefbf8000,0x4(%esp)
f01010f2:	ef 
f01010f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01010f6:	89 04 24             	mov    %eax,(%esp)
f01010f9:	e8 54 0f 00 00       	call   f0102052 <boot_map_segment>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the amapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here: 
	boot_map_segment(pgdir,KERNBASE,0xFFFFFFFF-KERNBASE+1,0,PTE_P|PTE_W);
f01010fe:	c7 44 24 10 03 00 00 	movl   $0x3,0x10(%esp)
f0101105:	00 
f0101106:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010110d:	00 
f010110e:	c7 44 24 08 00 00 00 	movl   $0x10000000,0x8(%esp)
f0101115:	10 
f0101116:	c7 44 24 04 00 00 00 	movl   $0xf0000000,0x4(%esp)
f010111d:	f0 
f010111e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101121:	89 04 24             	mov    %eax,(%esp)
f0101124:	e8 29 0f 00 00       	call   f0102052 <boot_map_segment>
	
	// Check that the initial page directory has been set up correctly.
	check_boot_pgdir();
f0101129:	e8 ef 04 00 00       	call   f010161d <check_boot_pgdir>
	// mapping, even though we are turning on paging and reconfiguring
	// segmentation.

	// Map VA 0:4MB same as VA KERNBASE, i.e. to PA 0:4MB.
	// (Limits our kernel to <4MB)
	pgdir[0] = pgdir[PDX(KERNBASE)];
f010112e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101131:	8b 90 00 0f 00 00    	mov    0xf00(%eax),%edx
f0101137:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010113a:	89 10                	mov    %edx,(%eax)

	// Install page table.
	lcr3(boot_cr3);
f010113c:	a1 24 7c 11 f0       	mov    0xf0117c24,%eax
f0101141:	89 45 cc             	mov    %eax,-0x34(%ebp)
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0101144:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101147:	0f 22 d8             	mov    %eax,%cr3

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f010114a:	0f 20 c0             	mov    %cr0,%eax
f010114d:	89 45 c8             	mov    %eax,-0x38(%ebp)
	return val;
f0101150:	8b 45 c8             	mov    -0x38(%ebp),%eax

	// Turn on paging.
	cr0 = rcr0();
f0101153:	89 45 d0             	mov    %eax,-0x30(%ebp)
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_EM|CR0_MP;
f0101156:	81 4d d0 2f 00 05 80 	orl    $0x8005002f,-0x30(%ebp)
	cr0 &= ~(CR0_TS|CR0_EM);
f010115d:	83 65 d0 f3          	andl   $0xfffffff3,-0x30(%ebp)
f0101161:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101164:	89 45 c4             	mov    %eax,-0x3c(%ebp)
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0101167:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010116a:	0f 22 c0             	mov    %eax,%cr0

	// Current mapping: KERNBASE+x => x => x.
	// (x < 4MB so uses paging pgdir[0])

	// Reload all segment registers.
	asm volatile("lgdt gdt_pd");
f010116d:	0f 01 15 90 75 11 f0 	lgdtl  0xf0117590
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0101174:	b8 23 00 00 00       	mov    $0x23,%eax
f0101179:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f010117b:	b8 23 00 00 00       	mov    $0x23,%eax
f0101180:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0101182:	b8 10 00 00 00       	mov    $0x10,%eax
f0101187:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0101189:	b8 10 00 00 00       	mov    $0x10,%eax
f010118e:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0101190:	b8 10 00 00 00       	mov    $0x10,%eax
f0101195:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));  // reload cs
f0101197:	ea 9e 11 10 f0 08 00 	ljmp   $0x8,$0xf010119e
	asm volatile("lldt %%ax" :: "a" (0));
f010119e:	b8 00 00 00 00       	mov    $0x0,%eax
f01011a3:	0f 00 d0             	lldt   %ax

	// Final mapping: KERNBASE+x => KERNBASE+x => x.

	// This mapping was only used after paging was turned on but
	// before the segment registers were reloaded.
	pgdir[0] = 0;
f01011a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011a9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// Flush the TLB for good measure, to kill the pgdir[0] mapping.
	lcr3(boot_cr3);
f01011af:	a1 24 7c 11 f0       	mov    0xf0117c24,%eax
f01011b4:	89 45 c0             	mov    %eax,-0x40(%ebp)
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01011b7:	8b 45 c0             	mov    -0x40(%ebp),%eax
f01011ba:	0f 22 d8             	mov    %eax,%cr3
}
f01011bd:	c9                   	leave  
f01011be:	c3                   	ret    

f01011bf <check_page_alloc>:
// Check the physical page allocator (page_alloc(), page_free(),
// and page_init()).
//
static void
check_page_alloc()
{
f01011bf:	55                   	push   %ebp
f01011c0:	89 e5                	mov    %esp,%ebp
f01011c2:	83 ec 38             	sub    $0x38,%esp
	struct Page_list fl;
	
        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	LIST_FOREACH(pp0, &page_free_list, pp_link)
f01011c5:	a1 fc 77 11 f0       	mov    0xf01177fc,%eax
f01011ca:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01011cd:	eb 2b                	jmp    f01011fa <check_page_alloc+0x3b>
		memset(page2kva(pp0), 0x97, 128);
f01011cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01011d2:	89 04 24             	mov    %eax,(%esp)
f01011d5:	e8 47 fb ff ff       	call   f0100d21 <page2kva>
f01011da:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f01011e1:	00 
f01011e2:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f01011e9:	00 
f01011ea:	89 04 24             	mov    %eax,(%esp)
f01011ed:	e8 9b 31 00 00       	call   f010438d <memset>
	struct Page_list fl;
	
        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	LIST_FOREACH(pp0, &page_free_list, pp_link)
f01011f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01011f5:	8b 00                	mov    (%eax),%eax
f01011f7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01011fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01011fd:	85 c0                	test   %eax,%eax
f01011ff:	75 ce                	jne    f01011cf <check_page_alloc+0x10>
		memset(page2kva(pp0), 0x97, 128);

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
f0101201:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
f0101208:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010120b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010120e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101211:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(page_alloc(&pp0) == 0);
f0101214:	8d 45 f0             	lea    -0x10(%ebp),%eax
f0101217:	89 04 24             	mov    %eax,(%esp)
f010121a:	e8 0f 0b 00 00       	call   f0101d2e <page_alloc>
f010121f:	85 c0                	test   %eax,%eax
f0101221:	74 24                	je     f0101247 <check_page_alloc+0x88>
f0101223:	c7 44 24 0c fc 4b 10 	movl   $0xf0104bfc,0xc(%esp)
f010122a:	f0 
f010122b:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0101232:	f0 
f0101233:	c7 44 24 04 2a 01 00 	movl   $0x12a,0x4(%esp)
f010123a:	00 
f010123b:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0101242:	e8 55 ee ff ff       	call   f010009c <_panic>
	assert(page_alloc(&pp1) == 0);
f0101247:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010124a:	89 04 24             	mov    %eax,(%esp)
f010124d:	e8 dc 0a 00 00       	call   f0101d2e <page_alloc>
f0101252:	85 c0                	test   %eax,%eax
f0101254:	74 24                	je     f010127a <check_page_alloc+0xbb>
f0101256:	c7 44 24 0c 27 4c 10 	movl   $0xf0104c27,0xc(%esp)
f010125d:	f0 
f010125e:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0101265:	f0 
f0101266:	c7 44 24 04 2b 01 00 	movl   $0x12b,0x4(%esp)
f010126d:	00 
f010126e:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0101275:	e8 22 ee ff ff       	call   f010009c <_panic>
	assert(page_alloc(&pp2) == 0);
f010127a:	8d 45 e8             	lea    -0x18(%ebp),%eax
f010127d:	89 04 24             	mov    %eax,(%esp)
f0101280:	e8 a9 0a 00 00       	call   f0101d2e <page_alloc>
f0101285:	85 c0                	test   %eax,%eax
f0101287:	74 24                	je     f01012ad <check_page_alloc+0xee>
f0101289:	c7 44 24 0c 3d 4c 10 	movl   $0xf0104c3d,0xc(%esp)
f0101290:	f0 
f0101291:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0101298:	f0 
f0101299:	c7 44 24 04 2c 01 00 	movl   $0x12c,0x4(%esp)
f01012a0:	00 
f01012a1:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01012a8:	e8 ef ed ff ff       	call   f010009c <_panic>

	assert(pp0);
f01012ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01012b0:	85 c0                	test   %eax,%eax
f01012b2:	75 24                	jne    f01012d8 <check_page_alloc+0x119>
f01012b4:	c7 44 24 0c 53 4c 10 	movl   $0xf0104c53,0xc(%esp)
f01012bb:	f0 
f01012bc:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01012c3:	f0 
f01012c4:	c7 44 24 04 2e 01 00 	movl   $0x12e,0x4(%esp)
f01012cb:	00 
f01012cc:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01012d3:	e8 c4 ed ff ff       	call   f010009c <_panic>
	assert(pp1 && pp1 != pp0);
f01012d8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012db:	85 c0                	test   %eax,%eax
f01012dd:	74 0a                	je     f01012e9 <check_page_alloc+0x12a>
f01012df:	8b 55 ec             	mov    -0x14(%ebp),%edx
f01012e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01012e5:	39 c2                	cmp    %eax,%edx
f01012e7:	75 24                	jne    f010130d <check_page_alloc+0x14e>
f01012e9:	c7 44 24 0c 57 4c 10 	movl   $0xf0104c57,0xc(%esp)
f01012f0:	f0 
f01012f1:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01012f8:	f0 
f01012f9:	c7 44 24 04 2f 01 00 	movl   $0x12f,0x4(%esp)
f0101300:	00 
f0101301:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0101308:	e8 8f ed ff ff       	call   f010009c <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010130d:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101310:	85 c0                	test   %eax,%eax
f0101312:	74 14                	je     f0101328 <check_page_alloc+0x169>
f0101314:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101317:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010131a:	39 c2                	cmp    %eax,%edx
f010131c:	74 0a                	je     f0101328 <check_page_alloc+0x169>
f010131e:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101321:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101324:	39 c2                	cmp    %eax,%edx
f0101326:	75 24                	jne    f010134c <check_page_alloc+0x18d>
f0101328:	c7 44 24 0c 6c 4c 10 	movl   $0xf0104c6c,0xc(%esp)
f010132f:	f0 
f0101330:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0101337:	f0 
f0101338:	c7 44 24 04 30 01 00 	movl   $0x130,0x4(%esp)
f010133f:	00 
f0101340:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0101347:	e8 50 ed ff ff       	call   f010009c <_panic>
        assert(page2pa(pp0) < npage*PGSIZE);
f010134c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010134f:	89 04 24             	mov    %eax,(%esp)
f0101352:	e8 66 f9 ff ff       	call   f0100cbd <page2pa>
f0101357:	8b 15 20 7c 11 f0    	mov    0xf0117c20,%edx
f010135d:	c1 e2 0c             	shl    $0xc,%edx
f0101360:	39 d0                	cmp    %edx,%eax
f0101362:	72 24                	jb     f0101388 <check_page_alloc+0x1c9>
f0101364:	c7 44 24 0c 8c 4c 10 	movl   $0xf0104c8c,0xc(%esp)
f010136b:	f0 
f010136c:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0101373:	f0 
f0101374:	c7 44 24 04 31 01 00 	movl   $0x131,0x4(%esp)
f010137b:	00 
f010137c:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0101383:	e8 14 ed ff ff       	call   f010009c <_panic>
        assert(page2pa(pp1) < npage*PGSIZE);
f0101388:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010138b:	89 04 24             	mov    %eax,(%esp)
f010138e:	e8 2a f9 ff ff       	call   f0100cbd <page2pa>
f0101393:	8b 15 20 7c 11 f0    	mov    0xf0117c20,%edx
f0101399:	c1 e2 0c             	shl    $0xc,%edx
f010139c:	39 d0                	cmp    %edx,%eax
f010139e:	72 24                	jb     f01013c4 <check_page_alloc+0x205>
f01013a0:	c7 44 24 0c a8 4c 10 	movl   $0xf0104ca8,0xc(%esp)
f01013a7:	f0 
f01013a8:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01013af:	f0 
f01013b0:	c7 44 24 04 32 01 00 	movl   $0x132,0x4(%esp)
f01013b7:	00 
f01013b8:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01013bf:	e8 d8 ec ff ff       	call   f010009c <_panic>
        assert(page2pa(pp2) < npage*PGSIZE);
f01013c4:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01013c7:	89 04 24             	mov    %eax,(%esp)
f01013ca:	e8 ee f8 ff ff       	call   f0100cbd <page2pa>
f01013cf:	8b 15 20 7c 11 f0    	mov    0xf0117c20,%edx
f01013d5:	c1 e2 0c             	shl    $0xc,%edx
f01013d8:	39 d0                	cmp    %edx,%eax
f01013da:	72 24                	jb     f0101400 <check_page_alloc+0x241>
f01013dc:	c7 44 24 0c c4 4c 10 	movl   $0xf0104cc4,0xc(%esp)
f01013e3:	f0 
f01013e4:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01013eb:	f0 
f01013ec:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
f01013f3:	00 
f01013f4:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01013fb:	e8 9c ec ff ff       	call   f010009c <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101400:	a1 fc 77 11 f0       	mov    0xf01177fc,%eax
f0101405:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	LIST_INIT(&page_free_list);
f0101408:	c7 05 fc 77 11 f0 00 	movl   $0x0,0xf01177fc
f010140f:	00 00 00 

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);
f0101412:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101415:	89 04 24             	mov    %eax,(%esp)
f0101418:	e8 11 09 00 00       	call   f0101d2e <page_alloc>
f010141d:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101420:	74 24                	je     f0101446 <check_page_alloc+0x287>
f0101422:	c7 44 24 0c e0 4c 10 	movl   $0xf0104ce0,0xc(%esp)
f0101429:	f0 
f010142a:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0101431:	f0 
f0101432:	c7 44 24 04 3a 01 00 	movl   $0x13a,0x4(%esp)
f0101439:	00 
f010143a:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0101441:	e8 56 ec ff ff       	call   f010009c <_panic>

        // free and re-allocate?
        page_free(pp0);
f0101446:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101449:	89 04 24             	mov    %eax,(%esp)
f010144c:	e8 30 09 00 00       	call   f0101d81 <page_free>
        page_free(pp1);
f0101451:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101454:	89 04 24             	mov    %eax,(%esp)
f0101457:	e8 25 09 00 00       	call   f0101d81 <page_free>
        page_free(pp2);
f010145c:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010145f:	89 04 24             	mov    %eax,(%esp)
f0101462:	e8 1a 09 00 00       	call   f0101d81 <page_free>
	pp0 = pp1 = pp2 = 0;
f0101467:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
f010146e:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101471:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101474:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101477:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(page_alloc(&pp0) == 0);
f010147a:	8d 45 f0             	lea    -0x10(%ebp),%eax
f010147d:	89 04 24             	mov    %eax,(%esp)
f0101480:	e8 a9 08 00 00       	call   f0101d2e <page_alloc>
f0101485:	85 c0                	test   %eax,%eax
f0101487:	74 24                	je     f01014ad <check_page_alloc+0x2ee>
f0101489:	c7 44 24 0c fc 4b 10 	movl   $0xf0104bfc,0xc(%esp)
f0101490:	f0 
f0101491:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0101498:	f0 
f0101499:	c7 44 24 04 41 01 00 	movl   $0x141,0x4(%esp)
f01014a0:	00 
f01014a1:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01014a8:	e8 ef eb ff ff       	call   f010009c <_panic>
	assert(page_alloc(&pp1) == 0);
f01014ad:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01014b0:	89 04 24             	mov    %eax,(%esp)
f01014b3:	e8 76 08 00 00       	call   f0101d2e <page_alloc>
f01014b8:	85 c0                	test   %eax,%eax
f01014ba:	74 24                	je     f01014e0 <check_page_alloc+0x321>
f01014bc:	c7 44 24 0c 27 4c 10 	movl   $0xf0104c27,0xc(%esp)
f01014c3:	f0 
f01014c4:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01014cb:	f0 
f01014cc:	c7 44 24 04 42 01 00 	movl   $0x142,0x4(%esp)
f01014d3:	00 
f01014d4:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01014db:	e8 bc eb ff ff       	call   f010009c <_panic>
	assert(page_alloc(&pp2) == 0);
f01014e0:	8d 45 e8             	lea    -0x18(%ebp),%eax
f01014e3:	89 04 24             	mov    %eax,(%esp)
f01014e6:	e8 43 08 00 00       	call   f0101d2e <page_alloc>
f01014eb:	85 c0                	test   %eax,%eax
f01014ed:	74 24                	je     f0101513 <check_page_alloc+0x354>
f01014ef:	c7 44 24 0c 3d 4c 10 	movl   $0xf0104c3d,0xc(%esp)
f01014f6:	f0 
f01014f7:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01014fe:	f0 
f01014ff:	c7 44 24 04 43 01 00 	movl   $0x143,0x4(%esp)
f0101506:	00 
f0101507:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f010150e:	e8 89 eb ff ff       	call   f010009c <_panic>
	assert(pp0);
f0101513:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101516:	85 c0                	test   %eax,%eax
f0101518:	75 24                	jne    f010153e <check_page_alloc+0x37f>
f010151a:	c7 44 24 0c 53 4c 10 	movl   $0xf0104c53,0xc(%esp)
f0101521:	f0 
f0101522:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0101529:	f0 
f010152a:	c7 44 24 04 44 01 00 	movl   $0x144,0x4(%esp)
f0101531:	00 
f0101532:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0101539:	e8 5e eb ff ff       	call   f010009c <_panic>
	assert(pp1 && pp1 != pp0);
f010153e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101541:	85 c0                	test   %eax,%eax
f0101543:	74 0a                	je     f010154f <check_page_alloc+0x390>
f0101545:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101548:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010154b:	39 c2                	cmp    %eax,%edx
f010154d:	75 24                	jne    f0101573 <check_page_alloc+0x3b4>
f010154f:	c7 44 24 0c 57 4c 10 	movl   $0xf0104c57,0xc(%esp)
f0101556:	f0 
f0101557:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f010155e:	f0 
f010155f:	c7 44 24 04 45 01 00 	movl   $0x145,0x4(%esp)
f0101566:	00 
f0101567:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f010156e:	e8 29 eb ff ff       	call   f010009c <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101573:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101576:	85 c0                	test   %eax,%eax
f0101578:	74 14                	je     f010158e <check_page_alloc+0x3cf>
f010157a:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010157d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101580:	39 c2                	cmp    %eax,%edx
f0101582:	74 0a                	je     f010158e <check_page_alloc+0x3cf>
f0101584:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101587:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010158a:	39 c2                	cmp    %eax,%edx
f010158c:	75 24                	jne    f01015b2 <check_page_alloc+0x3f3>
f010158e:	c7 44 24 0c 6c 4c 10 	movl   $0xf0104c6c,0xc(%esp)
f0101595:	f0 
f0101596:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f010159d:	f0 
f010159e:	c7 44 24 04 46 01 00 	movl   $0x146,0x4(%esp)
f01015a5:	00 
f01015a6:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01015ad:	e8 ea ea ff ff       	call   f010009c <_panic>
	assert(page_alloc(&pp) == -E_NO_MEM);
f01015b2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01015b5:	89 04 24             	mov    %eax,(%esp)
f01015b8:	e8 71 07 00 00       	call   f0101d2e <page_alloc>
f01015bd:	83 f8 fc             	cmp    $0xfffffffc,%eax
f01015c0:	74 24                	je     f01015e6 <check_page_alloc+0x427>
f01015c2:	c7 44 24 0c e0 4c 10 	movl   $0xf0104ce0,0xc(%esp)
f01015c9:	f0 
f01015ca:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01015d1:	f0 
f01015d2:	c7 44 24 04 47 01 00 	movl   $0x147,0x4(%esp)
f01015d9:	00 
f01015da:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01015e1:	e8 b6 ea ff ff       	call   f010009c <_panic>

	// give free list back
	page_free_list = fl;
f01015e6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01015e9:	a3 fc 77 11 f0       	mov    %eax,0xf01177fc

	// free the pages we took
	page_free(pp0);
f01015ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01015f1:	89 04 24             	mov    %eax,(%esp)
f01015f4:	e8 88 07 00 00       	call   f0101d81 <page_free>
	page_free(pp1);
f01015f9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01015fc:	89 04 24             	mov    %eax,(%esp)
f01015ff:	e8 7d 07 00 00       	call   f0101d81 <page_free>
	page_free(pp2);
f0101604:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101607:	89 04 24             	mov    %eax,(%esp)
f010160a:	e8 72 07 00 00       	call   f0101d81 <page_free>

	cprintf("check_page_alloc() succeeded!\n");
f010160f:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101616:	e8 ed 1e 00 00       	call   f0103508 <cprintf>
}
f010161b:	c9                   	leave  
f010161c:	c3                   	ret    

f010161d <check_boot_pgdir>:
//
static physaddr_t check_va2pa(pde_t *pgdir, uintptr_t va);

static void
check_boot_pgdir(void)
{
f010161d:	55                   	push   %ebp
f010161e:	89 e5                	mov    %esp,%ebp
f0101620:	83 ec 38             	sub    $0x38,%esp
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = boot_pgdir;
f0101623:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0101628:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
f010162b:	c7 45 ec 00 10 00 00 	movl   $0x1000,-0x14(%ebp)
f0101632:	8b 15 20 7c 11 f0    	mov    0xf0117c20,%edx
f0101638:	89 d0                	mov    %edx,%eax
f010163a:	01 c0                	add    %eax,%eax
f010163c:	01 d0                	add    %edx,%eax
f010163e:	c1 e0 02             	shl    $0x2,%eax
f0101641:	89 c2                	mov    %eax,%edx
f0101643:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101646:	01 d0                	add    %edx,%eax
f0101648:	83 e8 01             	sub    $0x1,%eax
f010164b:	89 45 e8             	mov    %eax,-0x18(%ebp)
f010164e:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101651:	ba 00 00 00 00       	mov    $0x0,%edx
f0101656:	f7 75 ec             	divl   -0x14(%ebp)
f0101659:	89 d0                	mov    %edx,%eax
f010165b:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010165e:	29 c2                	sub    %eax,%edx
f0101660:	89 d0                	mov    %edx,%eax
f0101662:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f0101665:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f010166c:	e9 89 00 00 00       	jmp    f01016fa <check_boot_pgdir+0xdd>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0101671:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101674:	2d 00 00 00 11       	sub    $0x11000000,%eax
f0101679:	89 44 24 04          	mov    %eax,0x4(%esp)
f010167d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101680:	89 04 24             	mov    %eax,(%esp)
f0101683:	e8 67 02 00 00       	call   f01018ef <check_va2pa>
f0101688:	8b 15 2c 7c 11 f0    	mov    0xf0117c2c,%edx
f010168e:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101691:	81 7d e0 ff ff ff ef 	cmpl   $0xefffffff,-0x20(%ebp)
f0101698:	77 23                	ja     f01016bd <check_boot_pgdir+0xa0>
f010169a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010169d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016a1:	c7 44 24 08 cc 4b 10 	movl   $0xf0104bcc,0x8(%esp)
f01016a8:	f0 
f01016a9:	c7 44 24 04 69 01 00 	movl   $0x169,0x4(%esp)
f01016b0:	00 
f01016b1:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01016b8:	e8 df e9 ff ff       	call   f010009c <_panic>
f01016bd:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01016c0:	8d 8a 00 00 00 10    	lea    0x10000000(%edx),%ecx
f01016c6:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01016c9:	01 ca                	add    %ecx,%edx
f01016cb:	39 d0                	cmp    %edx,%eax
f01016cd:	74 24                	je     f01016f3 <check_boot_pgdir+0xd6>
f01016cf:	c7 44 24 0c 20 4d 10 	movl   $0xf0104d20,0xc(%esp)
f01016d6:	f0 
f01016d7:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01016de:	f0 
f01016df:	c7 44 24 04 69 01 00 	movl   $0x169,0x4(%esp)
f01016e6:	00 
f01016e7:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01016ee:	e8 a9 e9 ff ff       	call   f010009c <_panic>

	pgdir = boot_pgdir;

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01016f3:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f01016fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01016fd:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
f0101700:	0f 82 6b ff ff ff    	jb     f0101671 <check_boot_pgdir+0x54>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	

	// check phys mem
	for (i = 0; i < npage; i += PGSIZE)
f0101706:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f010170d:	eb 47                	jmp    f0101756 <check_boot_pgdir+0x139>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010170f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101712:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101717:	89 44 24 04          	mov    %eax,0x4(%esp)
f010171b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010171e:	89 04 24             	mov    %eax,(%esp)
f0101721:	e8 c9 01 00 00       	call   f01018ef <check_va2pa>
f0101726:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0101729:	74 24                	je     f010174f <check_boot_pgdir+0x132>
f010172b:	c7 44 24 0c 54 4d 10 	movl   $0xf0104d54,0xc(%esp)
f0101732:	f0 
f0101733:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f010173a:	f0 
f010173b:	c7 44 24 04 6e 01 00 	movl   $0x16e,0x4(%esp)
f0101742:	00 
f0101743:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f010174a:	e8 4d e9 ff ff       	call   f010009c <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	

	// check phys mem
	for (i = 0; i < npage; i += PGSIZE)
f010174f:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f0101756:	a1 20 7c 11 f0       	mov    0xf0117c20,%eax
f010175b:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f010175e:	72 af                	jb     f010170f <check_boot_pgdir+0xf2>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0101760:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0101767:	e9 87 00 00 00       	jmp    f01017f3 <check_boot_pgdir+0x1d6>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010176c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010176f:	2d 00 80 40 10       	sub    $0x10408000,%eax
f0101774:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101778:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010177b:	89 04 24             	mov    %eax,(%esp)
f010177e:	e8 6c 01 00 00       	call   f01018ef <check_va2pa>
f0101783:	c7 45 dc 00 f0 10 f0 	movl   $0xf010f000,-0x24(%ebp)
f010178a:	81 7d dc ff ff ff ef 	cmpl   $0xefffffff,-0x24(%ebp)
f0101791:	77 23                	ja     f01017b6 <check_boot_pgdir+0x199>
f0101793:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101796:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010179a:	c7 44 24 08 cc 4b 10 	movl   $0xf0104bcc,0x8(%esp)
f01017a1:	f0 
f01017a2:	c7 44 24 04 72 01 00 	movl   $0x172,0x4(%esp)
f01017a9:	00 
f01017aa:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01017b1:	e8 e6 e8 ff ff       	call   f010009c <_panic>
f01017b6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01017b9:	8d 8a 00 00 00 10    	lea    0x10000000(%edx),%ecx
f01017bf:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01017c2:	01 ca                	add    %ecx,%edx
f01017c4:	39 d0                	cmp    %edx,%eax
f01017c6:	74 24                	je     f01017ec <check_boot_pgdir+0x1cf>
f01017c8:	c7 44 24 0c 7c 4d 10 	movl   $0xf0104d7c,0xc(%esp)
f01017cf:	f0 
f01017d0:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01017d7:	f0 
f01017d8:	c7 44 24 04 72 01 00 	movl   $0x172,0x4(%esp)
f01017df:	00 
f01017e0:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01017e7:	e8 b0 e8 ff ff       	call   f010009c <_panic>
	// check phys mem
	for (i = 0; i < npage; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01017ec:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f01017f3:	81 7d f4 ff 7f 00 00 	cmpl   $0x7fff,-0xc(%ebp)
f01017fa:	0f 86 6c ff ff ff    	jbe    f010176c <check_boot_pgdir+0x14f>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
f0101800:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0101807:	e9 c8 00 00 00       	jmp    f01018d4 <check_boot_pgdir+0x2b7>
		switch (i) {
f010180c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010180f:	2d bc 03 00 00       	sub    $0x3bc,%eax
f0101814:	83 f8 03             	cmp    $0x3,%eax
f0101817:	77 3b                	ja     f0101854 <check_boot_pgdir+0x237>
		case PDX(VPT):
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i]);
f0101819:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010181c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0101823:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101826:	01 d0                	add    %edx,%eax
f0101828:	8b 00                	mov    (%eax),%eax
f010182a:	85 c0                	test   %eax,%eax
f010182c:	75 24                	jne    f0101852 <check_boot_pgdir+0x235>
f010182e:	c7 44 24 0c c1 4d 10 	movl   $0xf0104dc1,0xc(%esp)
f0101835:	f0 
f0101836:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f010183d:	f0 
f010183e:	c7 44 24 04 7b 01 00 	movl   $0x17b,0x4(%esp)
f0101845:	00 
f0101846:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f010184d:	e8 4a e8 ff ff       	call   f010009c <_panic>
			break;
f0101852:	eb 7c                	jmp    f01018d0 <check_boot_pgdir+0x2b3>
		default:
			if (i >= PDX(KERNBASE))
f0101854:	81 7d f4 bf 03 00 00 	cmpl   $0x3bf,-0xc(%ebp)
f010185b:	76 39                	jbe    f0101896 <check_boot_pgdir+0x279>
				assert(pgdir[i]);
f010185d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101860:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0101867:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010186a:	01 d0                	add    %edx,%eax
f010186c:	8b 00                	mov    (%eax),%eax
f010186e:	85 c0                	test   %eax,%eax
f0101870:	75 5d                	jne    f01018cf <check_boot_pgdir+0x2b2>
f0101872:	c7 44 24 0c c1 4d 10 	movl   $0xf0104dc1,0xc(%esp)
f0101879:	f0 
f010187a:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0101881:	f0 
f0101882:	c7 44 24 04 7f 01 00 	movl   $0x17f,0x4(%esp)
f0101889:	00 
f010188a:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0101891:	e8 06 e8 ff ff       	call   f010009c <_panic>
			else
				assert(pgdir[i] == 0);
f0101896:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101899:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01018a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01018a3:	01 d0                	add    %edx,%eax
f01018a5:	8b 00                	mov    (%eax),%eax
f01018a7:	85 c0                	test   %eax,%eax
f01018a9:	74 24                	je     f01018cf <check_boot_pgdir+0x2b2>
f01018ab:	c7 44 24 0c ca 4d 10 	movl   $0xf0104dca,0xc(%esp)
f01018b2:	f0 
f01018b3:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01018ba:	f0 
f01018bb:	c7 44 24 04 81 01 00 	movl   $0x181,0x4(%esp)
f01018c2:	00 
f01018c3:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01018ca:	e8 cd e7 ff ff       	call   f010009c <_panic>
			break;
f01018cf:	90                   	nop
	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
f01018d0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
f01018d4:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
f01018db:	0f 86 2b ff ff ff    	jbe    f010180c <check_boot_pgdir+0x1ef>
			else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_boot_pgdir() succeeded!\n");
f01018e1:	c7 04 24 d8 4d 10 f0 	movl   $0xf0104dd8,(%esp)
f01018e8:	e8 1b 1c 00 00       	call   f0103508 <cprintf>
}
f01018ed:	c9                   	leave  
f01018ee:	c3                   	ret    

f01018ef <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_boot_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01018ef:	55                   	push   %ebp
f01018f0:	89 e5                	mov    %esp,%ebp
f01018f2:	83 ec 28             	sub    $0x28,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f01018f5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01018f8:	c1 e8 16             	shr    $0x16,%eax
f01018fb:	c1 e0 02             	shl    $0x2,%eax
f01018fe:	01 45 08             	add    %eax,0x8(%ebp)
	if (!(*pgdir & PTE_P))
f0101901:	8b 45 08             	mov    0x8(%ebp),%eax
f0101904:	8b 00                	mov    (%eax),%eax
f0101906:	83 e0 01             	and    $0x1,%eax
f0101909:	85 c0                	test   %eax,%eax
f010190b:	75 0a                	jne    f0101917 <check_va2pa+0x28>
		return ~0;
f010190d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101912:	e9 93 00 00 00       	jmp    f01019aa <check_va2pa+0xbb>
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0101917:	8b 45 08             	mov    0x8(%ebp),%eax
f010191a:	8b 00                	mov    (%eax),%eax
f010191c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101921:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101924:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101927:	c1 e8 0c             	shr    $0xc,%eax
f010192a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010192d:	a1 20 7c 11 f0       	mov    0xf0117c20,%eax
f0101932:	39 45 f0             	cmp    %eax,-0x10(%ebp)
f0101935:	72 23                	jb     f010195a <check_va2pa+0x6b>
f0101937:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010193a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010193e:	c7 44 24 08 68 4b 10 	movl   $0xf0104b68,0x8(%esp)
f0101945:	f0 
f0101946:	c7 44 24 04 95 01 00 	movl   $0x195,0x4(%esp)
f010194d:	00 
f010194e:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0101955:	e8 42 e7 ff ff       	call   f010009c <_panic>
f010195a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010195d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101962:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!(p[PTX(va)] & PTE_P))
f0101965:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101968:	c1 e8 0c             	shr    $0xc,%eax
f010196b:	25 ff 03 00 00       	and    $0x3ff,%eax
f0101970:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0101977:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010197a:	01 d0                	add    %edx,%eax
f010197c:	8b 00                	mov    (%eax),%eax
f010197e:	83 e0 01             	and    $0x1,%eax
f0101981:	85 c0                	test   %eax,%eax
f0101983:	75 07                	jne    f010198c <check_va2pa+0x9d>
		return ~0;
f0101985:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010198a:	eb 1e                	jmp    f01019aa <check_va2pa+0xbb>
	return PTE_ADDR(p[PTX(va)]);
f010198c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010198f:	c1 e8 0c             	shr    $0xc,%eax
f0101992:	25 ff 03 00 00       	and    $0x3ff,%eax
f0101997:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f010199e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01019a1:	01 d0                	add    %edx,%eax
f01019a3:	8b 00                	mov    (%eax),%eax
f01019a5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
}
f01019aa:	c9                   	leave  
f01019ab:	c3                   	ret    

f01019ac <page_init>:
// to allocate and deallocate physical memory via the page_free_list,
// and NEVER use boot_alloc()
//
void
page_init(void)
{
f01019ac:	55                   	push   %ebp
f01019ad:	89 e5                	mov    %esp,%ebp
f01019af:	53                   	push   %ebx
f01019b0:	83 ec 24             	sub    $0x24,%esp
	//     Some of it is in use, some is free. Where is the kernel?
	//     Which pages are used for page tables and other data structures?
	//
	// Change the code to reflect this.
	int i;
	LIST_INIT(&page_free_list);
f01019b3:	c7 05 fc 77 11 f0 00 	movl   $0x0,0xf01177fc
f01019ba:	00 00 00 
	for (i = 0; i < npage; i++) {
f01019bd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f01019c4:	e9 91 00 00 00       	jmp    f0101a5a <page_init+0xae>
		pages[i].pp_ref = 0;
f01019c9:	8b 0d 2c 7c 11 f0    	mov    0xf0117c2c,%ecx
f01019cf:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01019d2:	89 d0                	mov    %edx,%eax
f01019d4:	01 c0                	add    %eax,%eax
f01019d6:	01 d0                	add    %edx,%eax
f01019d8:	c1 e0 02             	shl    $0x2,%eax
f01019db:	01 c8                	add    %ecx,%eax
f01019dd:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
		LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
f01019e3:	8b 0d 2c 7c 11 f0    	mov    0xf0117c2c,%ecx
f01019e9:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01019ec:	89 d0                	mov    %edx,%eax
f01019ee:	01 c0                	add    %eax,%eax
f01019f0:	01 d0                	add    %edx,%eax
f01019f2:	c1 e0 02             	shl    $0x2,%eax
f01019f5:	01 c8                	add    %ecx,%eax
f01019f7:	8b 15 fc 77 11 f0    	mov    0xf01177fc,%edx
f01019fd:	89 10                	mov    %edx,(%eax)
f01019ff:	8b 00                	mov    (%eax),%eax
f0101a01:	85 c0                	test   %eax,%eax
f0101a03:	74 1d                	je     f0101a22 <page_init+0x76>
f0101a05:	8b 0d fc 77 11 f0    	mov    0xf01177fc,%ecx
f0101a0b:	8b 1d 2c 7c 11 f0    	mov    0xf0117c2c,%ebx
f0101a11:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101a14:	89 d0                	mov    %edx,%eax
f0101a16:	01 c0                	add    %eax,%eax
f0101a18:	01 d0                	add    %edx,%eax
f0101a1a:	c1 e0 02             	shl    $0x2,%eax
f0101a1d:	01 d8                	add    %ebx,%eax
f0101a1f:	89 41 04             	mov    %eax,0x4(%ecx)
f0101a22:	8b 0d 2c 7c 11 f0    	mov    0xf0117c2c,%ecx
f0101a28:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101a2b:	89 d0                	mov    %edx,%eax
f0101a2d:	01 c0                	add    %eax,%eax
f0101a2f:	01 d0                	add    %edx,%eax
f0101a31:	c1 e0 02             	shl    $0x2,%eax
f0101a34:	01 c8                	add    %ecx,%eax
f0101a36:	a3 fc 77 11 f0       	mov    %eax,0xf01177fc
f0101a3b:	8b 0d 2c 7c 11 f0    	mov    0xf0117c2c,%ecx
f0101a41:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101a44:	89 d0                	mov    %edx,%eax
f0101a46:	01 c0                	add    %eax,%eax
f0101a48:	01 d0                	add    %edx,%eax
f0101a4a:	c1 e0 02             	shl    $0x2,%eax
f0101a4d:	01 c8                	add    %ecx,%eax
f0101a4f:	c7 40 04 fc 77 11 f0 	movl   $0xf01177fc,0x4(%eax)
	//     Which pages are used for page tables and other data structures?
	//
	// Change the code to reflect this.
	int i;
	LIST_INIT(&page_free_list);
	for (i = 0; i < npage; i++) {
f0101a56:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
f0101a5a:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101a5d:	a1 20 7c 11 f0       	mov    0xf0117c20,%eax
f0101a62:	39 c2                	cmp    %eax,%edx
f0101a64:	0f 82 5f ff ff ff    	jb     f01019c9 <page_init+0x1d>
		pages[i].pp_ref = 0;
		LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
	}
	pages[0].pp_ref=1;
f0101a6a:	a1 2c 7c 11 f0       	mov    0xf0117c2c,%eax
f0101a6f:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
	LIST_REMOVE(&pages[0],pp_link);
f0101a75:	a1 2c 7c 11 f0       	mov    0xf0117c2c,%eax
f0101a7a:	8b 00                	mov    (%eax),%eax
f0101a7c:	85 c0                	test   %eax,%eax
f0101a7e:	74 13                	je     f0101a93 <page_init+0xe7>
f0101a80:	a1 2c 7c 11 f0       	mov    0xf0117c2c,%eax
f0101a85:	8b 00                	mov    (%eax),%eax
f0101a87:	8b 15 2c 7c 11 f0    	mov    0xf0117c2c,%edx
f0101a8d:	8b 52 04             	mov    0x4(%edx),%edx
f0101a90:	89 50 04             	mov    %edx,0x4(%eax)
f0101a93:	a1 2c 7c 11 f0       	mov    0xf0117c2c,%eax
f0101a98:	8b 40 04             	mov    0x4(%eax),%eax
f0101a9b:	8b 15 2c 7c 11 f0    	mov    0xf0117c2c,%edx
f0101aa1:	8b 12                	mov    (%edx),%edx
f0101aa3:	89 10                	mov    %edx,(%eax)
	for (i=IOPHYSMEM;i<EXTPHYSMEM;i+=PGSIZE)
f0101aa5:	c7 45 f4 00 00 0a 00 	movl   $0xa0000,-0xc(%ebp)
f0101aac:	e9 fa 00 00 00       	jmp    f0101bab <page_init+0x1ff>
	{
		pages[i/PGSIZE].pp_ref=1;
f0101ab1:	8b 0d 2c 7c 11 f0    	mov    0xf0117c2c,%ecx
f0101ab7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101aba:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101ac0:	85 c0                	test   %eax,%eax
f0101ac2:	0f 48 c2             	cmovs  %edx,%eax
f0101ac5:	c1 f8 0c             	sar    $0xc,%eax
f0101ac8:	89 c2                	mov    %eax,%edx
f0101aca:	89 d0                	mov    %edx,%eax
f0101acc:	01 c0                	add    %eax,%eax
f0101ace:	01 d0                	add    %edx,%eax
f0101ad0:	c1 e0 02             	shl    $0x2,%eax
f0101ad3:	01 c8                	add    %ecx,%eax
f0101ad5:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
		LIST_REMOVE(&pages[i/PGSIZE],pp_link);
f0101adb:	8b 0d 2c 7c 11 f0    	mov    0xf0117c2c,%ecx
f0101ae1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101ae4:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101aea:	85 c0                	test   %eax,%eax
f0101aec:	0f 48 c2             	cmovs  %edx,%eax
f0101aef:	c1 f8 0c             	sar    $0xc,%eax
f0101af2:	89 c2                	mov    %eax,%edx
f0101af4:	89 d0                	mov    %edx,%eax
f0101af6:	01 c0                	add    %eax,%eax
f0101af8:	01 d0                	add    %edx,%eax
f0101afa:	c1 e0 02             	shl    $0x2,%eax
f0101afd:	01 c8                	add    %ecx,%eax
f0101aff:	8b 00                	mov    (%eax),%eax
f0101b01:	85 c0                	test   %eax,%eax
f0101b03:	74 50                	je     f0101b55 <page_init+0x1a9>
f0101b05:	8b 0d 2c 7c 11 f0    	mov    0xf0117c2c,%ecx
f0101b0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101b0e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101b14:	85 c0                	test   %eax,%eax
f0101b16:	0f 48 c2             	cmovs  %edx,%eax
f0101b19:	c1 f8 0c             	sar    $0xc,%eax
f0101b1c:	89 c2                	mov    %eax,%edx
f0101b1e:	89 d0                	mov    %edx,%eax
f0101b20:	01 c0                	add    %eax,%eax
f0101b22:	01 d0                	add    %edx,%eax
f0101b24:	c1 e0 02             	shl    $0x2,%eax
f0101b27:	01 c8                	add    %ecx,%eax
f0101b29:	8b 08                	mov    (%eax),%ecx
f0101b2b:	8b 1d 2c 7c 11 f0    	mov    0xf0117c2c,%ebx
f0101b31:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101b34:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101b3a:	85 c0                	test   %eax,%eax
f0101b3c:	0f 48 c2             	cmovs  %edx,%eax
f0101b3f:	c1 f8 0c             	sar    $0xc,%eax
f0101b42:	89 c2                	mov    %eax,%edx
f0101b44:	89 d0                	mov    %edx,%eax
f0101b46:	01 c0                	add    %eax,%eax
f0101b48:	01 d0                	add    %edx,%eax
f0101b4a:	c1 e0 02             	shl    $0x2,%eax
f0101b4d:	01 d8                	add    %ebx,%eax
f0101b4f:	8b 40 04             	mov    0x4(%eax),%eax
f0101b52:	89 41 04             	mov    %eax,0x4(%ecx)
f0101b55:	8b 0d 2c 7c 11 f0    	mov    0xf0117c2c,%ecx
f0101b5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101b5e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101b64:	85 c0                	test   %eax,%eax
f0101b66:	0f 48 c2             	cmovs  %edx,%eax
f0101b69:	c1 f8 0c             	sar    $0xc,%eax
f0101b6c:	89 c2                	mov    %eax,%edx
f0101b6e:	89 d0                	mov    %edx,%eax
f0101b70:	01 c0                	add    %eax,%eax
f0101b72:	01 d0                	add    %edx,%eax
f0101b74:	c1 e0 02             	shl    $0x2,%eax
f0101b77:	01 c8                	add    %ecx,%eax
f0101b79:	8b 48 04             	mov    0x4(%eax),%ecx
f0101b7c:	8b 1d 2c 7c 11 f0    	mov    0xf0117c2c,%ebx
f0101b82:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101b85:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101b8b:	85 c0                	test   %eax,%eax
f0101b8d:	0f 48 c2             	cmovs  %edx,%eax
f0101b90:	c1 f8 0c             	sar    $0xc,%eax
f0101b93:	89 c2                	mov    %eax,%edx
f0101b95:	89 d0                	mov    %edx,%eax
f0101b97:	01 c0                	add    %eax,%eax
f0101b99:	01 d0                	add    %edx,%eax
f0101b9b:	c1 e0 02             	shl    $0x2,%eax
f0101b9e:	01 d8                	add    %ebx,%eax
f0101ba0:	8b 00                	mov    (%eax),%eax
f0101ba2:	89 01                	mov    %eax,(%ecx)
		pages[i].pp_ref = 0;
		LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
	}
	pages[0].pp_ref=1;
	LIST_REMOVE(&pages[0],pp_link);
	for (i=IOPHYSMEM;i<EXTPHYSMEM;i+=PGSIZE)
f0101ba4:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f0101bab:	81 7d f4 ff ff 0f 00 	cmpl   $0xfffff,-0xc(%ebp)
f0101bb2:	0f 8e f9 fe ff ff    	jle    f0101ab1 <page_init+0x105>
	{
		pages[i/PGSIZE].pp_ref=1;
		LIST_REMOVE(&pages[i/PGSIZE],pp_link);
	}	
	for (i=EXTPHYSMEM;i<PADDR((uint32_t)boot_freemem);i+=PGSIZE)
f0101bb8:	c7 45 f4 00 00 10 00 	movl   $0x100000,-0xc(%ebp)
f0101bbf:	e9 fa 00 00 00       	jmp    f0101cbe <page_init+0x312>
	{
				
		pages[i/PGSIZE].pp_ref=1;
f0101bc4:	8b 0d 2c 7c 11 f0    	mov    0xf0117c2c,%ecx
f0101bca:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101bcd:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101bd3:	85 c0                	test   %eax,%eax
f0101bd5:	0f 48 c2             	cmovs  %edx,%eax
f0101bd8:	c1 f8 0c             	sar    $0xc,%eax
f0101bdb:	89 c2                	mov    %eax,%edx
f0101bdd:	89 d0                	mov    %edx,%eax
f0101bdf:	01 c0                	add    %eax,%eax
f0101be1:	01 d0                	add    %edx,%eax
f0101be3:	c1 e0 02             	shl    $0x2,%eax
f0101be6:	01 c8                	add    %ecx,%eax
f0101be8:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
		LIST_REMOVE(&pages[i/PGSIZE],pp_link);
f0101bee:	8b 0d 2c 7c 11 f0    	mov    0xf0117c2c,%ecx
f0101bf4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101bf7:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101bfd:	85 c0                	test   %eax,%eax
f0101bff:	0f 48 c2             	cmovs  %edx,%eax
f0101c02:	c1 f8 0c             	sar    $0xc,%eax
f0101c05:	89 c2                	mov    %eax,%edx
f0101c07:	89 d0                	mov    %edx,%eax
f0101c09:	01 c0                	add    %eax,%eax
f0101c0b:	01 d0                	add    %edx,%eax
f0101c0d:	c1 e0 02             	shl    $0x2,%eax
f0101c10:	01 c8                	add    %ecx,%eax
f0101c12:	8b 00                	mov    (%eax),%eax
f0101c14:	85 c0                	test   %eax,%eax
f0101c16:	74 50                	je     f0101c68 <page_init+0x2bc>
f0101c18:	8b 0d 2c 7c 11 f0    	mov    0xf0117c2c,%ecx
f0101c1e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101c21:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101c27:	85 c0                	test   %eax,%eax
f0101c29:	0f 48 c2             	cmovs  %edx,%eax
f0101c2c:	c1 f8 0c             	sar    $0xc,%eax
f0101c2f:	89 c2                	mov    %eax,%edx
f0101c31:	89 d0                	mov    %edx,%eax
f0101c33:	01 c0                	add    %eax,%eax
f0101c35:	01 d0                	add    %edx,%eax
f0101c37:	c1 e0 02             	shl    $0x2,%eax
f0101c3a:	01 c8                	add    %ecx,%eax
f0101c3c:	8b 08                	mov    (%eax),%ecx
f0101c3e:	8b 1d 2c 7c 11 f0    	mov    0xf0117c2c,%ebx
f0101c44:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101c47:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101c4d:	85 c0                	test   %eax,%eax
f0101c4f:	0f 48 c2             	cmovs  %edx,%eax
f0101c52:	c1 f8 0c             	sar    $0xc,%eax
f0101c55:	89 c2                	mov    %eax,%edx
f0101c57:	89 d0                	mov    %edx,%eax
f0101c59:	01 c0                	add    %eax,%eax
f0101c5b:	01 d0                	add    %edx,%eax
f0101c5d:	c1 e0 02             	shl    $0x2,%eax
f0101c60:	01 d8                	add    %ebx,%eax
f0101c62:	8b 40 04             	mov    0x4(%eax),%eax
f0101c65:	89 41 04             	mov    %eax,0x4(%ecx)
f0101c68:	8b 0d 2c 7c 11 f0    	mov    0xf0117c2c,%ecx
f0101c6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101c71:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101c77:	85 c0                	test   %eax,%eax
f0101c79:	0f 48 c2             	cmovs  %edx,%eax
f0101c7c:	c1 f8 0c             	sar    $0xc,%eax
f0101c7f:	89 c2                	mov    %eax,%edx
f0101c81:	89 d0                	mov    %edx,%eax
f0101c83:	01 c0                	add    %eax,%eax
f0101c85:	01 d0                	add    %edx,%eax
f0101c87:	c1 e0 02             	shl    $0x2,%eax
f0101c8a:	01 c8                	add    %ecx,%eax
f0101c8c:	8b 48 04             	mov    0x4(%eax),%ecx
f0101c8f:	8b 1d 2c 7c 11 f0    	mov    0xf0117c2c,%ebx
f0101c95:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101c98:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101c9e:	85 c0                	test   %eax,%eax
f0101ca0:	0f 48 c2             	cmovs  %edx,%eax
f0101ca3:	c1 f8 0c             	sar    $0xc,%eax
f0101ca6:	89 c2                	mov    %eax,%edx
f0101ca8:	89 d0                	mov    %edx,%eax
f0101caa:	01 c0                	add    %eax,%eax
f0101cac:	01 d0                	add    %edx,%eax
f0101cae:	c1 e0 02             	shl    $0x2,%eax
f0101cb1:	01 d8                	add    %ebx,%eax
f0101cb3:	8b 00                	mov    (%eax),%eax
f0101cb5:	89 01                	mov    %eax,(%ecx)
	for (i=IOPHYSMEM;i<EXTPHYSMEM;i+=PGSIZE)
	{
		pages[i/PGSIZE].pp_ref=1;
		LIST_REMOVE(&pages[i/PGSIZE],pp_link);
	}	
	for (i=EXTPHYSMEM;i<PADDR((uint32_t)boot_freemem);i+=PGSIZE)
f0101cb7:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f0101cbe:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101cc1:	a1 f8 77 11 f0       	mov    0xf01177f8,%eax
f0101cc6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101cc9:	81 7d f0 ff ff ff ef 	cmpl   $0xefffffff,-0x10(%ebp)
f0101cd0:	77 23                	ja     f0101cf5 <page_init+0x349>
f0101cd2:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101cd5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101cd9:	c7 44 24 08 cc 4b 10 	movl   $0xf0104bcc,0x8(%esp)
f0101ce0:	f0 
f0101ce1:	c7 44 24 04 c4 01 00 	movl   $0x1c4,0x4(%esp)
f0101ce8:	00 
f0101ce9:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0101cf0:	e8 a7 e3 ff ff       	call   f010009c <_panic>
f0101cf5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101cf8:	05 00 00 00 10       	add    $0x10000000,%eax
f0101cfd:	39 c2                	cmp    %eax,%edx
f0101cff:	0f 82 bf fe ff ff    	jb     f0101bc4 <page_init+0x218>
	{
				
		pages[i/PGSIZE].pp_ref=1;
		LIST_REMOVE(&pages[i/PGSIZE],pp_link);
	}
}
f0101d05:	83 c4 24             	add    $0x24,%esp
f0101d08:	5b                   	pop    %ebx
f0101d09:	5d                   	pop    %ebp
f0101d0a:	c3                   	ret    

f0101d0b <page_initpp>:
// The result has null links and 0 refcount.
// Note that the corresponding physical page is NOT initialized!
//
static void
page_initpp(struct Page *pp)
{
f0101d0b:	55                   	push   %ebp
f0101d0c:	89 e5                	mov    %esp,%ebp
f0101d0e:	83 ec 18             	sub    $0x18,%esp
	memset(pp, 0, sizeof(*pp));
f0101d11:	c7 44 24 08 0c 00 00 	movl   $0xc,0x8(%esp)
f0101d18:	00 
f0101d19:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101d20:	00 
f0101d21:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d24:	89 04 24             	mov    %eax,(%esp)
f0101d27:	e8 61 26 00 00       	call   f010438d <memset>
}
f0101d2c:	c9                   	leave  
f0101d2d:	c3                   	ret    

f0101d2e <page_alloc>:
//
// Hint: use LIST_FIRST, LIST_REMOVE, and page_initpp
// Hint: pp_ref should not be incremented 
int
page_alloc(struct Page **pp_store)
{
f0101d2e:	55                   	push   %ebp
f0101d2f:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	if (LIST_FIRST(&page_free_list)!=NULL)
f0101d31:	a1 fc 77 11 f0       	mov    0xf01177fc,%eax
f0101d36:	85 c0                	test   %eax,%eax
f0101d38:	74 40                	je     f0101d7a <page_alloc+0x4c>
	{
		//page_initpp(*pp_store);
		*pp_store=LIST_FIRST(&page_free_list);
f0101d3a:	8b 15 fc 77 11 f0    	mov    0xf01177fc,%edx
f0101d40:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d43:	89 10                	mov    %edx,(%eax)
		LIST_REMOVE(*pp_store,pp_link);
f0101d45:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d48:	8b 00                	mov    (%eax),%eax
f0101d4a:	8b 00                	mov    (%eax),%eax
f0101d4c:	85 c0                	test   %eax,%eax
f0101d4e:	74 12                	je     f0101d62 <page_alloc+0x34>
f0101d50:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d53:	8b 00                	mov    (%eax),%eax
f0101d55:	8b 00                	mov    (%eax),%eax
f0101d57:	8b 55 08             	mov    0x8(%ebp),%edx
f0101d5a:	8b 12                	mov    (%edx),%edx
f0101d5c:	8b 52 04             	mov    0x4(%edx),%edx
f0101d5f:	89 50 04             	mov    %edx,0x4(%eax)
f0101d62:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d65:	8b 00                	mov    (%eax),%eax
f0101d67:	8b 40 04             	mov    0x4(%eax),%eax
f0101d6a:	8b 55 08             	mov    0x8(%ebp),%edx
f0101d6d:	8b 12                	mov    (%edx),%edx
f0101d6f:	8b 12                	mov    (%edx),%edx
f0101d71:	89 10                	mov    %edx,(%eax)
		return 0;
f0101d73:	b8 00 00 00 00       	mov    $0x0,%eax
f0101d78:	eb 05                	jmp    f0101d7f <page_alloc+0x51>
	}
	return -E_NO_MEM;
f0101d7a:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f0101d7f:	5d                   	pop    %ebp
f0101d80:	c3                   	ret    

f0101d81 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0101d81:	55                   	push   %ebp
f0101d82:	89 e5                	mov    %esp,%ebp
f0101d84:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	if (pp->pp_ref>0)
f0101d87:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d8a:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0101d8e:	66 85 c0             	test   %ax,%ax
f0101d91:	74 02                	je     f0101d95 <page_free+0x14>
		return ;
f0101d93:	eb 3c                	jmp    f0101dd1 <page_free+0x50>
	page_initpp(pp);
f0101d95:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d98:	89 04 24             	mov    %eax,(%esp)
f0101d9b:	e8 6b ff ff ff       	call   f0101d0b <page_initpp>
	LIST_INSERT_HEAD(&page_free_list,pp,pp_link);
f0101da0:	8b 15 fc 77 11 f0    	mov    0xf01177fc,%edx
f0101da6:	8b 45 08             	mov    0x8(%ebp),%eax
f0101da9:	89 10                	mov    %edx,(%eax)
f0101dab:	8b 45 08             	mov    0x8(%ebp),%eax
f0101dae:	8b 00                	mov    (%eax),%eax
f0101db0:	85 c0                	test   %eax,%eax
f0101db2:	74 0b                	je     f0101dbf <page_free+0x3e>
f0101db4:	a1 fc 77 11 f0       	mov    0xf01177fc,%eax
f0101db9:	8b 55 08             	mov    0x8(%ebp),%edx
f0101dbc:	89 50 04             	mov    %edx,0x4(%eax)
f0101dbf:	8b 45 08             	mov    0x8(%ebp),%eax
f0101dc2:	a3 fc 77 11 f0       	mov    %eax,0xf01177fc
f0101dc7:	8b 45 08             	mov    0x8(%ebp),%eax
f0101dca:	c7 40 04 fc 77 11 f0 	movl   $0xf01177fc,0x4(%eax)
}
f0101dd1:	c9                   	leave  
f0101dd2:	c3                   	ret    

f0101dd3 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0101dd3:	55                   	push   %ebp
f0101dd4:	89 e5                	mov    %esp,%ebp
f0101dd6:	83 ec 18             	sub    $0x18,%esp
	if (--pp->pp_ref == 0)
f0101dd9:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ddc:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0101de0:	8d 50 ff             	lea    -0x1(%eax),%edx
f0101de3:	8b 45 08             	mov    0x8(%ebp),%eax
f0101de6:	66 89 50 08          	mov    %dx,0x8(%eax)
f0101dea:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ded:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0101df1:	66 85 c0             	test   %ax,%ax
f0101df4:	75 0b                	jne    f0101e01 <page_decref+0x2e>
		page_free(pp);
f0101df6:	8b 45 08             	mov    0x8(%ebp),%eax
f0101df9:	89 04 24             	mov    %eax,(%esp)
f0101dfc:	e8 80 ff ff ff       	call   f0101d81 <page_free>
}
f0101e01:	c9                   	leave  
f0101e02:	c3                   	ret    

f0101e03 <pgdir_walk>:
//
// Hint: you can turn a Page * into the physical address of the
// page it refers to with page2pa() from kern/pmap.h.
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101e03:	55                   	push   %ebp
f0101e04:	89 e5                	mov    %esp,%ebp
f0101e06:	53                   	push   %ebx
f0101e07:	83 ec 34             	sub    $0x34,%esp
	// Fill this function in
	pte_t *t;
	struct Page *pa;
/*	if ((uint32_t)va==PGSIZE)
		cprintf("create=%d exist=%d\n ",create,pgdir[PDX(va)]&PTE_P);*/
	if ((pgdir[PDX(va)]&PTE_P)==0)
f0101e0a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101e0d:	c1 e8 16             	shr    $0x16,%eax
f0101e10:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0101e17:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e1a:	01 d0                	add    %edx,%eax
f0101e1c:	8b 00                	mov    (%eax),%eax
f0101e1e:	83 e0 01             	and    $0x1,%eax
f0101e21:	85 c0                	test   %eax,%eax
f0101e23:	0f 85 2f 01 00 00    	jne    f0101f58 <pgdir_walk+0x155>
	{
		if (create==0)
f0101e29:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101e2d:	75 0a                	jne    f0101e39 <pgdir_walk+0x36>
			return NULL;
f0101e2f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101e34:	e9 93 01 00 00       	jmp    f0101fcc <pgdir_walk+0x1c9>
		else
		{
			if (page_alloc(&pa)!=0)
f0101e39:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0101e3c:	89 04 24             	mov    %eax,(%esp)
f0101e3f:	e8 ea fe ff ff       	call   f0101d2e <page_alloc>
f0101e44:	85 c0                	test   %eax,%eax
f0101e46:	74 0a                	je     f0101e52 <pgdir_walk+0x4f>
				return NULL;
f0101e48:	b8 00 00 00 00       	mov    $0x0,%eax
f0101e4d:	e9 7a 01 00 00       	jmp    f0101fcc <pgdir_walk+0x1c9>
			else
			{
				pa->pp_ref=1;
f0101e52:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101e55:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
				memset(KADDR(page2pa(pa)),0,PGSIZE);
f0101e5b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101e5e:	89 04 24             	mov    %eax,(%esp)
f0101e61:	e8 57 ee ff ff       	call   f0100cbd <page2pa>
f0101e66:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101e69:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101e6c:	c1 e8 0c             	shr    $0xc,%eax
f0101e6f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101e72:	a1 20 7c 11 f0       	mov    0xf0117c20,%eax
f0101e77:	39 45 f0             	cmp    %eax,-0x10(%ebp)
f0101e7a:	72 23                	jb     f0101e9f <pgdir_walk+0x9c>
f0101e7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101e7f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101e83:	c7 44 24 08 68 4b 10 	movl   $0xf0104b68,0x8(%esp)
f0101e8a:	f0 
f0101e8b:	c7 44 24 04 2c 02 00 	movl   $0x22c,0x4(%esp)
f0101e92:	00 
f0101e93:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0101e9a:	e8 fd e1 ff ff       	call   f010009c <_panic>
f0101e9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101ea2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101ea7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101eae:	00 
f0101eaf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101eb6:	00 
f0101eb7:	89 04 24             	mov    %eax,(%esp)
f0101eba:	e8 ce 24 00 00       	call   f010438d <memset>
				pgdir[PDX(va)]=page2pa(pa)|PTE_P|PTE_W;
f0101ebf:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101ec2:	c1 e8 16             	shr    $0x16,%eax
f0101ec5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0101ecc:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ecf:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
f0101ed2:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101ed5:	89 04 24             	mov    %eax,(%esp)
f0101ed8:	e8 e0 ed ff ff       	call   f0100cbd <page2pa>
f0101edd:	83 c8 03             	or     $0x3,%eax
f0101ee0:	89 03                	mov    %eax,(%ebx)
				t=KADDR(PTE_ADDR(pgdir[PDX(va)]));
f0101ee2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101ee5:	c1 e8 16             	shr    $0x16,%eax
f0101ee8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0101eef:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ef2:	01 d0                	add    %edx,%eax
f0101ef4:	8b 00                	mov    (%eax),%eax
f0101ef6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101efb:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101efe:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101f01:	c1 e8 0c             	shr    $0xc,%eax
f0101f04:	89 45 e8             	mov    %eax,-0x18(%ebp)
f0101f07:	a1 20 7c 11 f0       	mov    0xf0117c20,%eax
f0101f0c:	39 45 e8             	cmp    %eax,-0x18(%ebp)
f0101f0f:	72 23                	jb     f0101f34 <pgdir_walk+0x131>
f0101f11:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101f14:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101f18:	c7 44 24 08 68 4b 10 	movl   $0xf0104b68,0x8(%esp)
f0101f1f:	f0 
f0101f20:	c7 44 24 04 2e 02 00 	movl   $0x22e,0x4(%esp)
f0101f27:	00 
f0101f28:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0101f2f:	e8 68 e1 ff ff       	call   f010009c <_panic>
f0101f34:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101f37:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101f3c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				return &t[PTX(va)];
f0101f3f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101f42:	c1 e8 0c             	shr    $0xc,%eax
f0101f45:	25 ff 03 00 00       	and    $0x3ff,%eax
f0101f4a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0101f51:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101f54:	01 d0                	add    %edx,%eax
f0101f56:	eb 74                	jmp    f0101fcc <pgdir_walk+0x1c9>
		}
		
	}
	else
	{
		t=KADDR(PTE_ADDR(pgdir[PDX(va)]));
f0101f58:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101f5b:	c1 e8 16             	shr    $0x16,%eax
f0101f5e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0101f65:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f68:	01 d0                	add    %edx,%eax
f0101f6a:	8b 00                	mov    (%eax),%eax
f0101f6c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101f71:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101f74:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101f77:	c1 e8 0c             	shr    $0xc,%eax
f0101f7a:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101f7d:	a1 20 7c 11 f0       	mov    0xf0117c20,%eax
f0101f82:	39 45 dc             	cmp    %eax,-0x24(%ebp)
f0101f85:	72 23                	jb     f0101faa <pgdir_walk+0x1a7>
f0101f87:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101f8a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101f8e:	c7 44 24 08 68 4b 10 	movl   $0xf0104b68,0x8(%esp)
f0101f95:	f0 
f0101f96:	c7 44 24 04 36 02 00 	movl   $0x236,0x4(%esp)
f0101f9d:	00 
f0101f9e:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0101fa5:	e8 f2 e0 ff ff       	call   f010009c <_panic>
f0101faa:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101fad:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101fb2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		return &t[PTX(va)];
f0101fb5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101fb8:	c1 e8 0c             	shr    $0xc,%eax
f0101fbb:	25 ff 03 00 00       	and    $0x3ff,%eax
f0101fc0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0101fc7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101fca:	01 d0                	add    %edx,%eax
	}
	return NULL;
}
f0101fcc:	83 c4 34             	add    $0x34,%esp
f0101fcf:	5b                   	pop    %ebx
f0101fd0:	5d                   	pop    %ebp
f0101fd1:	c3                   	ret    

f0101fd2 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm) 
{
f0101fd2:	55                   	push   %ebp
f0101fd3:	89 e5                	mov    %esp,%ebp
f0101fd5:	83 ec 28             	sub    $0x28,%esp
	// Fill this function in
	pte_t *pte;
	pte=pgdir_walk(pgdir,va,1);
f0101fd8:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101fdf:	00 
f0101fe0:	8b 45 10             	mov    0x10(%ebp),%eax
f0101fe3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101fe7:	8b 45 08             	mov    0x8(%ebp),%eax
f0101fea:	89 04 24             	mov    %eax,(%esp)
f0101fed:	e8 11 fe ff ff       	call   f0101e03 <pgdir_walk>
f0101ff2:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (pte==NULL)
f0101ff5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0101ff9:	75 07                	jne    f0102002 <page_insert+0x30>
		return -E_NO_MEM;
f0101ffb:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0102000:	eb 4e                	jmp    f0102050 <page_insert+0x7e>
	pp->pp_ref++;	
f0102002:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102005:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0102009:	8d 50 01             	lea    0x1(%eax),%edx
f010200c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010200f:	66 89 50 08          	mov    %dx,0x8(%eax)
	if ((*pte&PTE_P)!=0)
f0102013:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102016:	8b 00                	mov    (%eax),%eax
f0102018:	83 e0 01             	and    $0x1,%eax
f010201b:	85 c0                	test   %eax,%eax
f010201d:	74 12                	je     f0102031 <page_insert+0x5f>
		page_remove(pgdir,va);
f010201f:	8b 45 10             	mov    0x10(%ebp),%eax
f0102022:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102026:	8b 45 08             	mov    0x8(%ebp),%eax
f0102029:	89 04 24             	mov    %eax,(%esp)
f010202c:	e8 22 01 00 00       	call   f0102153 <page_remove>
	*pte=page2pa(pp)|perm|PTE_P;
f0102031:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102034:	89 04 24             	mov    %eax,(%esp)
f0102037:	e8 81 ec ff ff       	call   f0100cbd <page2pa>
f010203c:	8b 55 14             	mov    0x14(%ebp),%edx
f010203f:	09 d0                	or     %edx,%eax
f0102041:	83 c8 01             	or     $0x1,%eax
f0102044:	89 c2                	mov    %eax,%edx
f0102046:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102049:	89 10                	mov    %edx,(%eax)
	
	return 0;
f010204b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102050:	c9                   	leave  
f0102051:	c3                   	ret    

f0102052 <boot_map_segment>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, physaddr_t pa, int perm)
{
f0102052:	55                   	push   %ebp
f0102053:	89 e5                	mov    %esp,%ebp
f0102055:	83 ec 28             	sub    $0x28,%esp
	// Fill this function in
	int i;
	pte_t *t;
	size=ROUNDUP(size,PGSIZE);
f0102058:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
f010205f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102062:	8b 55 10             	mov    0x10(%ebp),%edx
f0102065:	01 d0                	add    %edx,%eax
f0102067:	83 e8 01             	sub    $0x1,%eax
f010206a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010206d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102070:	ba 00 00 00 00       	mov    $0x0,%edx
f0102075:	f7 75 f0             	divl   -0x10(%ebp)
f0102078:	89 d0                	mov    %edx,%eax
f010207a:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010207d:	29 c2                	sub    %eax,%edx
f010207f:	89 d0                	mov    %edx,%eax
f0102081:	89 45 10             	mov    %eax,0x10(%ebp)
	for (i=0;i<size;i+=PGSIZE)
f0102084:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f010208b:	eb 6a                	jmp    f01020f7 <boot_map_segment+0xa5>
	{
		t=pgdir_walk(pgdir,(void*)(la+i),1);
f010208d:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102090:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102093:	01 d0                	add    %edx,%eax
f0102095:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010209c:	00 
f010209d:	89 44 24 04          	mov    %eax,0x4(%esp)
f01020a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01020a4:	89 04 24             	mov    %eax,(%esp)
f01020a7:	e8 57 fd ff ff       	call   f0101e03 <pgdir_walk>
f01020ac:	89 45 e8             	mov    %eax,-0x18(%ebp)
		assert(t!=NULL);
f01020af:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01020b3:	75 24                	jne    f01020d9 <boot_map_segment+0x87>
f01020b5:	c7 44 24 0c f7 4d 10 	movl   $0xf0104df7,0xc(%esp)
f01020bc:	f0 
f01020bd:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01020c4:	f0 
f01020c5:	c7 44 24 04 73 02 00 	movl   $0x273,0x4(%esp)
f01020cc:	00 
f01020cd:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01020d4:	e8 c3 df ff ff       	call   f010009c <_panic>
		*t=(pa+i) | perm | PTE_P;
f01020d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01020dc:	8b 45 14             	mov    0x14(%ebp),%eax
f01020df:	01 c2                	add    %eax,%edx
f01020e1:	8b 45 18             	mov    0x18(%ebp),%eax
f01020e4:	09 d0                	or     %edx,%eax
f01020e6:	83 c8 01             	or     $0x1,%eax
f01020e9:	89 c2                	mov    %eax,%edx
f01020eb:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01020ee:	89 10                	mov    %edx,(%eax)
{
	// Fill this function in
	int i;
	pte_t *t;
	size=ROUNDUP(size,PGSIZE);
	for (i=0;i<size;i+=PGSIZE)
f01020f0:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f01020f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01020fa:	3b 45 10             	cmp    0x10(%ebp),%eax
f01020fd:	72 8e                	jb     f010208d <boot_map_segment+0x3b>
	{
		t=pgdir_walk(pgdir,(void*)(la+i),1);
		assert(t!=NULL);
		*t=(pa+i) | perm | PTE_P;
	}
}
f01020ff:	c9                   	leave  
f0102100:	c3                   	ret    

f0102101 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0102101:	55                   	push   %ebp
f0102102:	89 e5                	mov    %esp,%ebp
f0102104:	83 ec 28             	sub    $0x28,%esp
	// Fill this function in
	pte_t *t;
	t=pgdir_walk(pgdir,va,0);
f0102107:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010210e:	00 
f010210f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102112:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102116:	8b 45 08             	mov    0x8(%ebp),%eax
f0102119:	89 04 24             	mov    %eax,(%esp)
f010211c:	e8 e2 fc ff ff       	call   f0101e03 <pgdir_walk>
f0102121:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (t==NULL)
f0102124:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0102128:	75 07                	jne    f0102131 <page_lookup+0x30>
		return 0;
f010212a:	b8 00 00 00 00       	mov    $0x0,%eax
f010212f:	eb 20                	jmp    f0102151 <page_lookup+0x50>
	if (pte_store!=NULL)
f0102131:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0102135:	74 08                	je     f010213f <page_lookup+0x3e>
		*pte_store=t;
f0102137:	8b 45 10             	mov    0x10(%ebp),%eax
f010213a:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010213d:	89 10                	mov    %edx,(%eax)
/*	if ((uint32_t)va==PGSIZE)
		cprintf("PPN:%x   npage:%d    va:%x    KADDR:%x\n",PTE_ADDR(*t),npage,va,t);// EDITTTTTTT*/
	return pa2page(PTE_ADDR(*t));
f010213f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102142:	8b 00                	mov    (%eax),%eax
f0102144:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102149:	89 04 24             	mov    %eax,(%esp)
f010214c:	e8 82 eb ff ff       	call   f0100cd3 <pa2page>
}
f0102151:	c9                   	leave  
f0102152:	c3                   	ret    

f0102153 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0102153:	55                   	push   %ebp
f0102154:	89 e5                	mov    %esp,%ebp
f0102156:	83 ec 28             	sub    $0x28,%esp
	// Fill this function in
	pte_t *t;
	struct Page *pg;
	pg=page_lookup(pgdir,va,&t);
f0102159:	8d 45 f0             	lea    -0x10(%ebp),%eax
f010215c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102160:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102163:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102167:	8b 45 08             	mov    0x8(%ebp),%eax
f010216a:	89 04 24             	mov    %eax,(%esp)
f010216d:	e8 8f ff ff ff       	call   f0102101 <page_lookup>
f0102172:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (pg==NULL)
f0102175:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0102179:	74 2d                	je     f01021a8 <page_remove+0x55>
		return ;
	page_decref(pg);
f010217b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010217e:	89 04 24             	mov    %eax,(%esp)
f0102181:	e8 4d fc ff ff       	call   f0101dd3 <page_decref>
	if (t!=NULL)
f0102186:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102189:	85 c0                	test   %eax,%eax
f010218b:	74 09                	je     f0102196 <page_remove+0x43>
		*t=0;
f010218d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102190:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir,va);
f0102196:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102199:	89 44 24 04          	mov    %eax,0x4(%esp)
f010219d:	8b 45 08             	mov    0x8(%ebp),%eax
f01021a0:	89 04 24             	mov    %eax,(%esp)
f01021a3:	e8 02 00 00 00       	call   f01021aa <tlb_invalidate>
}
f01021a8:	c9                   	leave  
f01021a9:	c3                   	ret    

f01021aa <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01021aa:	55                   	push   %ebp
f01021ab:	89 e5                	mov    %esp,%ebp
f01021ad:	83 ec 10             	sub    $0x10,%esp
f01021b0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01021b3:	89 45 fc             	mov    %eax,-0x4(%ebp)
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01021b6:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01021b9:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01021bc:	c9                   	leave  
f01021bd:	c3                   	ret    

f01021be <page_check>:

// check page_insert, page_remove, &c
static void
page_check(void)
{
f01021be:	55                   	push   %ebp
f01021bf:	89 e5                	mov    %esp,%ebp
f01021c1:	53                   	push   %ebx
f01021c2:	83 ec 54             	sub    $0x54,%esp
	pte_t *ptep, *ptep1;
	void *va;
	int i;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
f01021c5:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
f01021cc:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01021cf:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01021d2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01021d5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	assert(page_alloc(&pp0) == 0);
f01021d8:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f01021db:	89 04 24             	mov    %eax,(%esp)
f01021de:	e8 4b fb ff ff       	call   f0101d2e <page_alloc>
f01021e3:	85 c0                	test   %eax,%eax
f01021e5:	74 24                	je     f010220b <page_check+0x4d>
f01021e7:	c7 44 24 0c fc 4b 10 	movl   $0xf0104bfc,0xc(%esp)
f01021ee:	f0 
f01021ef:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01021f6:	f0 
f01021f7:	c7 44 24 04 c7 02 00 	movl   $0x2c7,0x4(%esp)
f01021fe:	00 
f01021ff:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102206:	e8 91 de ff ff       	call   f010009c <_panic>
	assert(page_alloc(&pp1) == 0);
f010220b:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010220e:	89 04 24             	mov    %eax,(%esp)
f0102211:	e8 18 fb ff ff       	call   f0101d2e <page_alloc>
f0102216:	85 c0                	test   %eax,%eax
f0102218:	74 24                	je     f010223e <page_check+0x80>
f010221a:	c7 44 24 0c 27 4c 10 	movl   $0xf0104c27,0xc(%esp)
f0102221:	f0 
f0102222:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102229:	f0 
f010222a:	c7 44 24 04 c8 02 00 	movl   $0x2c8,0x4(%esp)
f0102231:	00 
f0102232:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102239:	e8 5e de ff ff       	call   f010009c <_panic>
	assert(page_alloc(&pp2) == 0);
f010223e:	8d 45 cc             	lea    -0x34(%ebp),%eax
f0102241:	89 04 24             	mov    %eax,(%esp)
f0102244:	e8 e5 fa ff ff       	call   f0101d2e <page_alloc>
f0102249:	85 c0                	test   %eax,%eax
f010224b:	74 24                	je     f0102271 <page_check+0xb3>
f010224d:	c7 44 24 0c 3d 4c 10 	movl   $0xf0104c3d,0xc(%esp)
f0102254:	f0 
f0102255:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f010225c:	f0 
f010225d:	c7 44 24 04 c9 02 00 	movl   $0x2c9,0x4(%esp)
f0102264:	00 
f0102265:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f010226c:	e8 2b de ff ff       	call   f010009c <_panic>

	assert(pp0);
f0102271:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102274:	85 c0                	test   %eax,%eax
f0102276:	75 24                	jne    f010229c <page_check+0xde>
f0102278:	c7 44 24 0c 53 4c 10 	movl   $0xf0104c53,0xc(%esp)
f010227f:	f0 
f0102280:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102287:	f0 
f0102288:	c7 44 24 04 cb 02 00 	movl   $0x2cb,0x4(%esp)
f010228f:	00 
f0102290:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102297:	e8 00 de ff ff       	call   f010009c <_panic>
	assert(pp1 && pp1 != pp0);
f010229c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010229f:	85 c0                	test   %eax,%eax
f01022a1:	74 0a                	je     f01022ad <page_check+0xef>
f01022a3:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01022a6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022a9:	39 c2                	cmp    %eax,%edx
f01022ab:	75 24                	jne    f01022d1 <page_check+0x113>
f01022ad:	c7 44 24 0c 57 4c 10 	movl   $0xf0104c57,0xc(%esp)
f01022b4:	f0 
f01022b5:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01022bc:	f0 
f01022bd:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
f01022c4:	00 
f01022c5:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01022cc:	e8 cb dd ff ff       	call   f010009c <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01022d1:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01022d4:	85 c0                	test   %eax,%eax
f01022d6:	74 14                	je     f01022ec <page_check+0x12e>
f01022d8:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01022db:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01022de:	39 c2                	cmp    %eax,%edx
f01022e0:	74 0a                	je     f01022ec <page_check+0x12e>
f01022e2:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01022e5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022e8:	39 c2                	cmp    %eax,%edx
f01022ea:	75 24                	jne    f0102310 <page_check+0x152>
f01022ec:	c7 44 24 0c 6c 4c 10 	movl   $0xf0104c6c,0xc(%esp)
f01022f3:	f0 
f01022f4:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01022fb:	f0 
f01022fc:	c7 44 24 04 cd 02 00 	movl   $0x2cd,0x4(%esp)
f0102303:	00 
f0102304:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f010230b:	e8 8c dd ff ff       	call   f010009c <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0102310:	a1 fc 77 11 f0       	mov    0xf01177fc,%eax
f0102315:	89 45 c8             	mov    %eax,-0x38(%ebp)
	LIST_INIT(&page_free_list);
f0102318:	c7 05 fc 77 11 f0 00 	movl   $0x0,0xf01177fc
f010231f:	00 00 00 

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);
f0102322:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0102325:	89 04 24             	mov    %eax,(%esp)
f0102328:	e8 01 fa ff ff       	call   f0101d2e <page_alloc>
f010232d:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0102330:	74 24                	je     f0102356 <page_check+0x198>
f0102332:	c7 44 24 0c e0 4c 10 	movl   $0xf0104ce0,0xc(%esp)
f0102339:	f0 
f010233a:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102341:	f0 
f0102342:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
f0102349:	00 
f010234a:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102351:	e8 46 dd ff ff       	call   f010009c <_panic>
	
	// there is no page allocated at address 0
	assert(page_lookup(boot_pgdir, (void *) 0x0, &ptep) == NULL);
f0102356:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f010235b:	8d 55 c4             	lea    -0x3c(%ebp),%edx
f010235e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0102362:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102369:	00 
f010236a:	89 04 24             	mov    %eax,(%esp)
f010236d:	e8 8f fd ff ff       	call   f0102101 <page_lookup>
f0102372:	85 c0                	test   %eax,%eax
f0102374:	74 24                	je     f010239a <page_check+0x1dc>
f0102376:	c7 44 24 0c 00 4e 10 	movl   $0xf0104e00,0xc(%esp)
f010237d:	f0 
f010237e:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102385:	f0 
f0102386:	c7 44 24 04 d7 02 00 	movl   $0x2d7,0x4(%esp)
f010238d:	00 
f010238e:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102395:	e8 02 dd ff ff       	call   f010009c <_panic>

	// there is no free memory, so we can't allocate a page table 
	assert(page_insert(boot_pgdir, pp1, 0x0, 0) < 0);
f010239a:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010239d:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f01023a2:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01023a9:	00 
f01023aa:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01023b1:	00 
f01023b2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01023b6:	89 04 24             	mov    %eax,(%esp)
f01023b9:	e8 14 fc ff ff       	call   f0101fd2 <page_insert>
f01023be:	85 c0                	test   %eax,%eax
f01023c0:	78 24                	js     f01023e6 <page_check+0x228>
f01023c2:	c7 44 24 0c 38 4e 10 	movl   $0xf0104e38,0xc(%esp)
f01023c9:	f0 
f01023ca:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01023d1:	f0 
f01023d2:	c7 44 24 04 da 02 00 	movl   $0x2da,0x4(%esp)
f01023d9:	00 
f01023da:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01023e1:	e8 b6 dc ff ff       	call   f010009c <_panic>
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01023e6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023e9:	89 04 24             	mov    %eax,(%esp)
f01023ec:	e8 90 f9 ff ff       	call   f0101d81 <page_free>
	assert(page_insert(boot_pgdir, pp1, 0x0, 0) == 0);
f01023f1:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01023f4:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f01023f9:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0102400:	00 
f0102401:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102408:	00 
f0102409:	89 54 24 04          	mov    %edx,0x4(%esp)
f010240d:	89 04 24             	mov    %eax,(%esp)
f0102410:	e8 bd fb ff ff       	call   f0101fd2 <page_insert>
f0102415:	85 c0                	test   %eax,%eax
f0102417:	74 24                	je     f010243d <page_check+0x27f>
f0102419:	c7 44 24 0c 64 4e 10 	movl   $0xf0104e64,0xc(%esp)
f0102420:	f0 
f0102421:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102428:	f0 
f0102429:	c7 44 24 04 dd 02 00 	movl   $0x2dd,0x4(%esp)
f0102430:	00 
f0102431:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102438:	e8 5f dc ff ff       	call   f010009c <_panic>
	assert(PTE_ADDR(boot_pgdir[0]) == page2pa(pp0));
f010243d:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102442:	8b 00                	mov    (%eax),%eax
f0102444:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102449:	89 c3                	mov    %eax,%ebx
f010244b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010244e:	89 04 24             	mov    %eax,(%esp)
f0102451:	e8 67 e8 ff ff       	call   f0100cbd <page2pa>
f0102456:	39 c3                	cmp    %eax,%ebx
f0102458:	74 24                	je     f010247e <page_check+0x2c0>
f010245a:	c7 44 24 0c 90 4e 10 	movl   $0xf0104e90,0xc(%esp)
f0102461:	f0 
f0102462:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102469:	f0 
f010246a:	c7 44 24 04 de 02 00 	movl   $0x2de,0x4(%esp)
f0102471:	00 
f0102472:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102479:	e8 1e dc ff ff       	call   f010009c <_panic>
	assert(check_va2pa(boot_pgdir, 0x0) == page2pa(pp1));
f010247e:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102483:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010248a:	00 
f010248b:	89 04 24             	mov    %eax,(%esp)
f010248e:	e8 5c f4 ff ff       	call   f01018ef <check_va2pa>
f0102493:	89 c3                	mov    %eax,%ebx
f0102495:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102498:	89 04 24             	mov    %eax,(%esp)
f010249b:	e8 1d e8 ff ff       	call   f0100cbd <page2pa>
f01024a0:	39 c3                	cmp    %eax,%ebx
f01024a2:	74 24                	je     f01024c8 <page_check+0x30a>
f01024a4:	c7 44 24 0c b8 4e 10 	movl   $0xf0104eb8,0xc(%esp)
f01024ab:	f0 
f01024ac:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01024b3:	f0 
f01024b4:	c7 44 24 04 df 02 00 	movl   $0x2df,0x4(%esp)
f01024bb:	00 
f01024bc:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01024c3:	e8 d4 db ff ff       	call   f010009c <_panic>
	assert(pp1->pp_ref == 1);
f01024c8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01024cb:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f01024cf:	66 83 f8 01          	cmp    $0x1,%ax
f01024d3:	74 24                	je     f01024f9 <page_check+0x33b>
f01024d5:	c7 44 24 0c e5 4e 10 	movl   $0xf0104ee5,0xc(%esp)
f01024dc:	f0 
f01024dd:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01024e4:	f0 
f01024e5:	c7 44 24 04 e0 02 00 	movl   $0x2e0,0x4(%esp)
f01024ec:	00 
f01024ed:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01024f4:	e8 a3 db ff ff       	call   f010009c <_panic>
	assert(pp0->pp_ref == 1);
f01024f9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01024fc:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0102500:	66 83 f8 01          	cmp    $0x1,%ax
f0102504:	74 24                	je     f010252a <page_check+0x36c>
f0102506:	c7 44 24 0c f6 4e 10 	movl   $0xf0104ef6,0xc(%esp)
f010250d:	f0 
f010250e:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102515:	f0 
f0102516:	c7 44 24 04 e1 02 00 	movl   $0x2e1,0x4(%esp)
f010251d:	00 
f010251e:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102525:	e8 72 db ff ff       	call   f010009c <_panic>
	
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table         
	assert(page_insert(boot_pgdir, pp2, (void*) PGSIZE, 0) == 0);
f010252a:	8b 55 cc             	mov    -0x34(%ebp),%edx
f010252d:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102532:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0102539:	00 
f010253a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102541:	00 
f0102542:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102546:	89 04 24             	mov    %eax,(%esp)
f0102549:	e8 84 fa ff ff       	call   f0101fd2 <page_insert>
f010254e:	85 c0                	test   %eax,%eax
f0102550:	74 24                	je     f0102576 <page_check+0x3b8>
f0102552:	c7 44 24 0c 08 4f 10 	movl   $0xf0104f08,0xc(%esp)
f0102559:	f0 
f010255a:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102561:	f0 
f0102562:	c7 44 24 04 e4 02 00 	movl   $0x2e4,0x4(%esp)
f0102569:	00 
f010256a:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102571:	e8 26 db ff ff       	call   f010009c <_panic>
	//cprintf("%x %x\n",check_va2pa(boot_pgdir, PGSIZE),page2pa(pp2));
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp2));
f0102576:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f010257b:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102582:	00 
f0102583:	89 04 24             	mov    %eax,(%esp)
f0102586:	e8 64 f3 ff ff       	call   f01018ef <check_va2pa>
f010258b:	89 c3                	mov    %eax,%ebx
f010258d:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102590:	89 04 24             	mov    %eax,(%esp)
f0102593:	e8 25 e7 ff ff       	call   f0100cbd <page2pa>
f0102598:	39 c3                	cmp    %eax,%ebx
f010259a:	74 24                	je     f01025c0 <page_check+0x402>
f010259c:	c7 44 24 0c 40 4f 10 	movl   $0xf0104f40,0xc(%esp)
f01025a3:	f0 
f01025a4:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01025ab:	f0 
f01025ac:	c7 44 24 04 e6 02 00 	movl   $0x2e6,0x4(%esp)
f01025b3:	00 
f01025b4:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01025bb:	e8 dc da ff ff       	call   f010009c <_panic>
	assert(pp2->pp_ref == 1);
f01025c0:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01025c3:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f01025c7:	66 83 f8 01          	cmp    $0x1,%ax
f01025cb:	74 24                	je     f01025f1 <page_check+0x433>
f01025cd:	c7 44 24 0c 70 4f 10 	movl   $0xf0104f70,0xc(%esp)
f01025d4:	f0 
f01025d5:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01025dc:	f0 
f01025dd:	c7 44 24 04 e7 02 00 	movl   $0x2e7,0x4(%esp)
f01025e4:	00 
f01025e5:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01025ec:	e8 ab da ff ff       	call   f010009c <_panic>
	
	// should be no free memory  WRONG!!
	assert(page_alloc(&pp) == -E_NO_MEM);
f01025f1:	8d 45 d8             	lea    -0x28(%ebp),%eax
f01025f4:	89 04 24             	mov    %eax,(%esp)
f01025f7:	e8 32 f7 ff ff       	call   f0101d2e <page_alloc>
f01025fc:	83 f8 fc             	cmp    $0xfffffffc,%eax
f01025ff:	74 24                	je     f0102625 <page_check+0x467>
f0102601:	c7 44 24 0c e0 4c 10 	movl   $0xf0104ce0,0xc(%esp)
f0102608:	f0 
f0102609:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102610:	f0 
f0102611:	c7 44 24 04 ea 02 00 	movl   $0x2ea,0x4(%esp)
f0102618:	00 
f0102619:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102620:	e8 77 da ff ff       	call   f010009c <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(boot_pgdir, pp2, (void*) PGSIZE, 0) == 0);
f0102625:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0102628:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f010262d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0102634:	00 
f0102635:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010263c:	00 
f010263d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102641:	89 04 24             	mov    %eax,(%esp)
f0102644:	e8 89 f9 ff ff       	call   f0101fd2 <page_insert>
f0102649:	85 c0                	test   %eax,%eax
f010264b:	74 24                	je     f0102671 <page_check+0x4b3>
f010264d:	c7 44 24 0c 08 4f 10 	movl   $0xf0104f08,0xc(%esp)
f0102654:	f0 
f0102655:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f010265c:	f0 
f010265d:	c7 44 24 04 ed 02 00 	movl   $0x2ed,0x4(%esp)
f0102664:	00 
f0102665:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f010266c:	e8 2b da ff ff       	call   f010009c <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp2));
f0102671:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102676:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010267d:	00 
f010267e:	89 04 24             	mov    %eax,(%esp)
f0102681:	e8 69 f2 ff ff       	call   f01018ef <check_va2pa>
f0102686:	89 c3                	mov    %eax,%ebx
f0102688:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010268b:	89 04 24             	mov    %eax,(%esp)
f010268e:	e8 2a e6 ff ff       	call   f0100cbd <page2pa>
f0102693:	39 c3                	cmp    %eax,%ebx
f0102695:	74 24                	je     f01026bb <page_check+0x4fd>
f0102697:	c7 44 24 0c 40 4f 10 	movl   $0xf0104f40,0xc(%esp)
f010269e:	f0 
f010269f:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01026a6:	f0 
f01026a7:	c7 44 24 04 ee 02 00 	movl   $0x2ee,0x4(%esp)
f01026ae:	00 
f01026af:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01026b6:	e8 e1 d9 ff ff       	call   f010009c <_panic>
	assert(pp2->pp_ref == 1);
f01026bb:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01026be:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f01026c2:	66 83 f8 01          	cmp    $0x1,%ax
f01026c6:	74 24                	je     f01026ec <page_check+0x52e>
f01026c8:	c7 44 24 0c 70 4f 10 	movl   $0xf0104f70,0xc(%esp)
f01026cf:	f0 
f01026d0:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01026d7:	f0 
f01026d8:	c7 44 24 04 ef 02 00 	movl   $0x2ef,0x4(%esp)
f01026df:	00 
f01026e0:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01026e7:	e8 b0 d9 ff ff       	call   f010009c <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(page_alloc(&pp) == -E_NO_MEM);
f01026ec:	8d 45 d8             	lea    -0x28(%ebp),%eax
f01026ef:	89 04 24             	mov    %eax,(%esp)
f01026f2:	e8 37 f6 ff ff       	call   f0101d2e <page_alloc>
f01026f7:	83 f8 fc             	cmp    $0xfffffffc,%eax
f01026fa:	74 24                	je     f0102720 <page_check+0x562>
f01026fc:	c7 44 24 0c e0 4c 10 	movl   $0xf0104ce0,0xc(%esp)
f0102703:	f0 
f0102704:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f010270b:	f0 
f010270c:	c7 44 24 04 f3 02 00 	movl   $0x2f3,0x4(%esp)
f0102713:	00 
f0102714:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f010271b:	e8 7c d9 ff ff       	call   f010009c <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = KADDR(PTE_ADDR(boot_pgdir[PDX(PGSIZE)]));
f0102720:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102725:	8b 00                	mov    (%eax),%eax
f0102727:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010272c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010272f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102732:	c1 e8 0c             	shr    $0xc,%eax
f0102735:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102738:	a1 20 7c 11 f0       	mov    0xf0117c20,%eax
f010273d:	39 45 ec             	cmp    %eax,-0x14(%ebp)
f0102740:	72 23                	jb     f0102765 <page_check+0x5a7>
f0102742:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102745:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102749:	c7 44 24 08 68 4b 10 	movl   $0xf0104b68,0x8(%esp)
f0102750:	f0 
f0102751:	c7 44 24 04 f6 02 00 	movl   $0x2f6,0x4(%esp)
f0102758:	00 
f0102759:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102760:	e8 37 d9 ff ff       	call   f010009c <_panic>
f0102765:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102768:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010276d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	assert(pgdir_walk(boot_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102770:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102775:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010277c:	00 
f010277d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102784:	00 
f0102785:	89 04 24             	mov    %eax,(%esp)
f0102788:	e8 76 f6 ff ff       	call   f0101e03 <pgdir_walk>
f010278d:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0102790:	83 c2 04             	add    $0x4,%edx
f0102793:	39 d0                	cmp    %edx,%eax
f0102795:	74 24                	je     f01027bb <page_check+0x5fd>
f0102797:	c7 44 24 0c 84 4f 10 	movl   $0xf0104f84,0xc(%esp)
f010279e:	f0 
f010279f:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01027a6:	f0 
f01027a7:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
f01027ae:	00 
f01027af:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01027b6:	e8 e1 d8 ff ff       	call   f010009c <_panic>

	// should be able to change permissions too.
	assert(page_insert(boot_pgdir, pp2, (void*) PGSIZE, PTE_U) == 0);
f01027bb:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01027be:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f01027c3:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f01027ca:	00 
f01027cb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01027d2:	00 
f01027d3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01027d7:	89 04 24             	mov    %eax,(%esp)
f01027da:	e8 f3 f7 ff ff       	call   f0101fd2 <page_insert>
f01027df:	85 c0                	test   %eax,%eax
f01027e1:	74 24                	je     f0102807 <page_check+0x649>
f01027e3:	c7 44 24 0c c4 4f 10 	movl   $0xf0104fc4,0xc(%esp)
f01027ea:	f0 
f01027eb:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01027f2:	f0 
f01027f3:	c7 44 24 04 fa 02 00 	movl   $0x2fa,0x4(%esp)
f01027fa:	00 
f01027fb:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102802:	e8 95 d8 ff ff       	call   f010009c <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp2));
f0102807:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f010280c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102813:	00 
f0102814:	89 04 24             	mov    %eax,(%esp)
f0102817:	e8 d3 f0 ff ff       	call   f01018ef <check_va2pa>
f010281c:	89 c3                	mov    %eax,%ebx
f010281e:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102821:	89 04 24             	mov    %eax,(%esp)
f0102824:	e8 94 e4 ff ff       	call   f0100cbd <page2pa>
f0102829:	39 c3                	cmp    %eax,%ebx
f010282b:	74 24                	je     f0102851 <page_check+0x693>
f010282d:	c7 44 24 0c 40 4f 10 	movl   $0xf0104f40,0xc(%esp)
f0102834:	f0 
f0102835:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f010283c:	f0 
f010283d:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
f0102844:	00 
f0102845:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f010284c:	e8 4b d8 ff ff       	call   f010009c <_panic>
	assert(pp2->pp_ref == 1);
f0102851:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102854:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0102858:	66 83 f8 01          	cmp    $0x1,%ax
f010285c:	74 24                	je     f0102882 <page_check+0x6c4>
f010285e:	c7 44 24 0c 70 4f 10 	movl   $0xf0104f70,0xc(%esp)
f0102865:	f0 
f0102866:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f010286d:	f0 
f010286e:	c7 44 24 04 fc 02 00 	movl   $0x2fc,0x4(%esp)
f0102875:	00 
f0102876:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f010287d:	e8 1a d8 ff ff       	call   f010009c <_panic>
	assert(*pgdir_walk(boot_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102882:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102887:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010288e:	00 
f010288f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102896:	00 
f0102897:	89 04 24             	mov    %eax,(%esp)
f010289a:	e8 64 f5 ff ff       	call   f0101e03 <pgdir_walk>
f010289f:	8b 00                	mov    (%eax),%eax
f01028a1:	83 e0 04             	and    $0x4,%eax
f01028a4:	85 c0                	test   %eax,%eax
f01028a6:	75 24                	jne    f01028cc <page_check+0x70e>
f01028a8:	c7 44 24 0c 00 50 10 	movl   $0xf0105000,0xc(%esp)
f01028af:	f0 
f01028b0:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01028b7:	f0 
f01028b8:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f01028bf:	00 
f01028c0:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01028c7:	e8 d0 d7 ff ff       	call   f010009c <_panic>
	
	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(boot_pgdir, pp0, (void*) PTSIZE, 0) < 0);
f01028cc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01028cf:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f01028d4:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01028db:	00 
f01028dc:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f01028e3:	00 
f01028e4:	89 54 24 04          	mov    %edx,0x4(%esp)
f01028e8:	89 04 24             	mov    %eax,(%esp)
f01028eb:	e8 e2 f6 ff ff       	call   f0101fd2 <page_insert>
f01028f0:	85 c0                	test   %eax,%eax
f01028f2:	78 24                	js     f0102918 <page_check+0x75a>
f01028f4:	c7 44 24 0c 34 50 10 	movl   $0xf0105034,0xc(%esp)
f01028fb:	f0 
f01028fc:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102903:	f0 
f0102904:	c7 44 24 04 00 03 00 	movl   $0x300,0x4(%esp)
f010290b:	00 
f010290c:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102913:	e8 84 d7 ff ff       	call   f010009c <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(boot_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102918:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010291b:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102920:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0102927:	00 
f0102928:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010292f:	00 
f0102930:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102934:	89 04 24             	mov    %eax,(%esp)
f0102937:	e8 96 f6 ff ff       	call   f0101fd2 <page_insert>
f010293c:	85 c0                	test   %eax,%eax
f010293e:	74 24                	je     f0102964 <page_check+0x7a6>
f0102940:	c7 44 24 0c 68 50 10 	movl   $0xf0105068,0xc(%esp)
f0102947:	f0 
f0102948:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f010294f:	f0 
f0102950:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f0102957:	00 
f0102958:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f010295f:	e8 38 d7 ff ff       	call   f010009c <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(boot_pgdir, 0) == page2pa(pp1));
f0102964:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102969:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102970:	00 
f0102971:	89 04 24             	mov    %eax,(%esp)
f0102974:	e8 76 ef ff ff       	call   f01018ef <check_va2pa>
f0102979:	89 c3                	mov    %eax,%ebx
f010297b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010297e:	89 04 24             	mov    %eax,(%esp)
f0102981:	e8 37 e3 ff ff       	call   f0100cbd <page2pa>
f0102986:	39 c3                	cmp    %eax,%ebx
f0102988:	74 24                	je     f01029ae <page_check+0x7f0>
f010298a:	c7 44 24 0c a0 50 10 	movl   $0xf01050a0,0xc(%esp)
f0102991:	f0 
f0102992:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102999:	f0 
f010299a:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f01029a1:	00 
f01029a2:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01029a9:	e8 ee d6 ff ff       	call   f010009c <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp1));
f01029ae:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f01029b3:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01029ba:	00 
f01029bb:	89 04 24             	mov    %eax,(%esp)
f01029be:	e8 2c ef ff ff       	call   f01018ef <check_va2pa>
f01029c3:	89 c3                	mov    %eax,%ebx
f01029c5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01029c8:	89 04 24             	mov    %eax,(%esp)
f01029cb:	e8 ed e2 ff ff       	call   f0100cbd <page2pa>
f01029d0:	39 c3                	cmp    %eax,%ebx
f01029d2:	74 24                	je     f01029f8 <page_check+0x83a>
f01029d4:	c7 44 24 0c cc 50 10 	movl   $0xf01050cc,0xc(%esp)
f01029db:	f0 
f01029dc:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f01029e3:	f0 
f01029e4:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f01029eb:	00 
f01029ec:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f01029f3:	e8 a4 d6 ff ff       	call   f010009c <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01029f8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01029fb:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f01029ff:	66 83 f8 02          	cmp    $0x2,%ax
f0102a03:	74 24                	je     f0102a29 <page_check+0x86b>
f0102a05:	c7 44 24 0c fc 50 10 	movl   $0xf01050fc,0xc(%esp)
f0102a0c:	f0 
f0102a0d:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102a14:	f0 
f0102a15:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f0102a1c:	00 
f0102a1d:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102a24:	e8 73 d6 ff ff       	call   f010009c <_panic>
	assert(pp2->pp_ref == 0);
f0102a29:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102a2c:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0102a30:	66 85 c0             	test   %ax,%ax
f0102a33:	74 24                	je     f0102a59 <page_check+0x89b>
f0102a35:	c7 44 24 0c 0d 51 10 	movl   $0xf010510d,0xc(%esp)
f0102a3c:	f0 
f0102a3d:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102a44:	f0 
f0102a45:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0102a4c:	00 
f0102a4d:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102a54:	e8 43 d6 ff ff       	call   f010009c <_panic>

	// pp2 should be returned by page_alloc
	assert(page_alloc(&pp) == 0 && pp == pp2);
f0102a59:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0102a5c:	89 04 24             	mov    %eax,(%esp)
f0102a5f:	e8 ca f2 ff ff       	call   f0101d2e <page_alloc>
f0102a64:	85 c0                	test   %eax,%eax
f0102a66:	75 0a                	jne    f0102a72 <page_check+0x8b4>
f0102a68:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102a6b:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102a6e:	39 c2                	cmp    %eax,%edx
f0102a70:	74 24                	je     f0102a96 <page_check+0x8d8>
f0102a72:	c7 44 24 0c 20 51 10 	movl   $0xf0105120,0xc(%esp)
f0102a79:	f0 
f0102a7a:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102a81:	f0 
f0102a82:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
f0102a89:	00 
f0102a8a:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102a91:	e8 06 d6 ff ff       	call   f010009c <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(boot_pgdir, 0x0);
f0102a96:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102a9b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102aa2:	00 
f0102aa3:	89 04 24             	mov    %eax,(%esp)
f0102aa6:	e8 a8 f6 ff ff       	call   f0102153 <page_remove>
	assert(check_va2pa(boot_pgdir, 0x0) == ~0);
f0102aab:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102ab0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102ab7:	00 
f0102ab8:	89 04 24             	mov    %eax,(%esp)
f0102abb:	e8 2f ee ff ff       	call   f01018ef <check_va2pa>
f0102ac0:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102ac3:	74 24                	je     f0102ae9 <page_check+0x92b>
f0102ac5:	c7 44 24 0c 44 51 10 	movl   $0xf0105144,0xc(%esp)
f0102acc:	f0 
f0102acd:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102ad4:	f0 
f0102ad5:	c7 44 24 04 11 03 00 	movl   $0x311,0x4(%esp)
f0102adc:	00 
f0102add:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102ae4:	e8 b3 d5 ff ff       	call   f010009c <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp1));
f0102ae9:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102aee:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102af5:	00 
f0102af6:	89 04 24             	mov    %eax,(%esp)
f0102af9:	e8 f1 ed ff ff       	call   f01018ef <check_va2pa>
f0102afe:	89 c3                	mov    %eax,%ebx
f0102b00:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102b03:	89 04 24             	mov    %eax,(%esp)
f0102b06:	e8 b2 e1 ff ff       	call   f0100cbd <page2pa>
f0102b0b:	39 c3                	cmp    %eax,%ebx
f0102b0d:	74 24                	je     f0102b33 <page_check+0x975>
f0102b0f:	c7 44 24 0c cc 50 10 	movl   $0xf01050cc,0xc(%esp)
f0102b16:	f0 
f0102b17:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102b1e:	f0 
f0102b1f:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f0102b26:	00 
f0102b27:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102b2e:	e8 69 d5 ff ff       	call   f010009c <_panic>
	assert(pp1->pp_ref == 1);
f0102b33:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102b36:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0102b3a:	66 83 f8 01          	cmp    $0x1,%ax
f0102b3e:	74 24                	je     f0102b64 <page_check+0x9a6>
f0102b40:	c7 44 24 0c e5 4e 10 	movl   $0xf0104ee5,0xc(%esp)
f0102b47:	f0 
f0102b48:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102b4f:	f0 
f0102b50:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f0102b57:	00 
f0102b58:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102b5f:	e8 38 d5 ff ff       	call   f010009c <_panic>
	assert(pp2->pp_ref == 0);
f0102b64:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102b67:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0102b6b:	66 85 c0             	test   %ax,%ax
f0102b6e:	74 24                	je     f0102b94 <page_check+0x9d6>
f0102b70:	c7 44 24 0c 0d 51 10 	movl   $0xf010510d,0xc(%esp)
f0102b77:	f0 
f0102b78:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102b7f:	f0 
f0102b80:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0102b87:	00 
f0102b88:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102b8f:	e8 08 d5 ff ff       	call   f010009c <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(boot_pgdir, (void*) PGSIZE);
f0102b94:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102b99:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102ba0:	00 
f0102ba1:	89 04 24             	mov    %eax,(%esp)
f0102ba4:	e8 aa f5 ff ff       	call   f0102153 <page_remove>
	assert(check_va2pa(boot_pgdir, 0x0) == ~0);
f0102ba9:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102bae:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102bb5:	00 
f0102bb6:	89 04 24             	mov    %eax,(%esp)
f0102bb9:	e8 31 ed ff ff       	call   f01018ef <check_va2pa>
f0102bbe:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102bc1:	74 24                	je     f0102be7 <page_check+0xa29>
f0102bc3:	c7 44 24 0c 44 51 10 	movl   $0xf0105144,0xc(%esp)
f0102bca:	f0 
f0102bcb:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102bd2:	f0 
f0102bd3:	c7 44 24 04 18 03 00 	movl   $0x318,0x4(%esp)
f0102bda:	00 
f0102bdb:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102be2:	e8 b5 d4 ff ff       	call   f010009c <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == ~0);
f0102be7:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102bec:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102bf3:	00 
f0102bf4:	89 04 24             	mov    %eax,(%esp)
f0102bf7:	e8 f3 ec ff ff       	call   f01018ef <check_va2pa>
f0102bfc:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102bff:	74 24                	je     f0102c25 <page_check+0xa67>
f0102c01:	c7 44 24 0c 68 51 10 	movl   $0xf0105168,0xc(%esp)
f0102c08:	f0 
f0102c09:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102c10:	f0 
f0102c11:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f0102c18:	00 
f0102c19:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102c20:	e8 77 d4 ff ff       	call   f010009c <_panic>
	assert(pp1->pp_ref == 0);
f0102c25:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c28:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0102c2c:	66 85 c0             	test   %ax,%ax
f0102c2f:	74 24                	je     f0102c55 <page_check+0xa97>
f0102c31:	c7 44 24 0c 8e 51 10 	movl   $0xf010518e,0xc(%esp)
f0102c38:	f0 
f0102c39:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102c40:	f0 
f0102c41:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
f0102c48:	00 
f0102c49:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102c50:	e8 47 d4 ff ff       	call   f010009c <_panic>
	assert(pp2->pp_ref == 0);
f0102c55:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102c58:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0102c5c:	66 85 c0             	test   %ax,%ax
f0102c5f:	74 24                	je     f0102c85 <page_check+0xac7>
f0102c61:	c7 44 24 0c 0d 51 10 	movl   $0xf010510d,0xc(%esp)
f0102c68:	f0 
f0102c69:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102c70:	f0 
f0102c71:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0102c78:	00 
f0102c79:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102c80:	e8 17 d4 ff ff       	call   f010009c <_panic>

	// so it should be returned by page_alloc
	assert(page_alloc(&pp) == 0 && pp == pp1);
f0102c85:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0102c88:	89 04 24             	mov    %eax,(%esp)
f0102c8b:	e8 9e f0 ff ff       	call   f0101d2e <page_alloc>
f0102c90:	85 c0                	test   %eax,%eax
f0102c92:	75 0a                	jne    f0102c9e <page_check+0xae0>
f0102c94:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102c97:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c9a:	39 c2                	cmp    %eax,%edx
f0102c9c:	74 24                	je     f0102cc2 <page_check+0xb04>
f0102c9e:	c7 44 24 0c a0 51 10 	movl   $0xf01051a0,0xc(%esp)
f0102ca5:	f0 
f0102ca6:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102cad:	f0 
f0102cae:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f0102cb5:	00 
f0102cb6:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102cbd:	e8 da d3 ff ff       	call   f010009c <_panic>

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);
f0102cc2:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0102cc5:	89 04 24             	mov    %eax,(%esp)
f0102cc8:	e8 61 f0 ff ff       	call   f0101d2e <page_alloc>
f0102ccd:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0102cd0:	74 24                	je     f0102cf6 <page_check+0xb38>
f0102cd2:	c7 44 24 0c e0 4c 10 	movl   $0xf0104ce0,0xc(%esp)
f0102cd9:	f0 
f0102cda:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102ce1:	f0 
f0102ce2:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0102ce9:	00 
f0102cea:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102cf1:	e8 a6 d3 ff ff       	call   f010009c <_panic>
	page_remove(boot_pgdir, 0x0);
	assert(pp2->pp_ref == 0);
#endif

	// forcibly take pp0 back
	assert(PTE_ADDR(boot_pgdir[0]) == page2pa(pp0));
f0102cf6:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102cfb:	8b 00                	mov    (%eax),%eax
f0102cfd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102d02:	89 c3                	mov    %eax,%ebx
f0102d04:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d07:	89 04 24             	mov    %eax,(%esp)
f0102d0a:	e8 ae df ff ff       	call   f0100cbd <page2pa>
f0102d0f:	39 c3                	cmp    %eax,%ebx
f0102d11:	74 24                	je     f0102d37 <page_check+0xb79>
f0102d13:	c7 44 24 0c 90 4e 10 	movl   $0xf0104e90,0xc(%esp)
f0102d1a:	f0 
f0102d1b:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102d22:	f0 
f0102d23:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0102d2a:	00 
f0102d2b:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102d32:	e8 65 d3 ff ff       	call   f010009c <_panic>
	boot_pgdir[0] = 0;
f0102d37:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102d3c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102d42:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d45:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0102d49:	66 83 f8 01          	cmp    $0x1,%ax
f0102d4d:	74 24                	je     f0102d73 <page_check+0xbb5>
f0102d4f:	c7 44 24 0c f6 4e 10 	movl   $0xf0104ef6,0xc(%esp)
f0102d56:	f0 
f0102d57:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102d5e:	f0 
f0102d5f:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f0102d66:	00 
f0102d67:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102d6e:	e8 29 d3 ff ff       	call   f010009c <_panic>
	pp0->pp_ref = 0;
f0102d73:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d76:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
	
	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102d7c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d7f:	89 04 24             	mov    %eax,(%esp)
f0102d82:	e8 fa ef ff ff       	call   f0101d81 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
f0102d87:	c7 45 e8 00 10 40 00 	movl   $0x401000,-0x18(%ebp)
	ptep = pgdir_walk(boot_pgdir, va, 1);
f0102d8e:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102d93:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102d9a:	00 
f0102d9b:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102d9e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102da2:	89 04 24             	mov    %eax,(%esp)
f0102da5:	e8 59 f0 ff ff       	call   f0101e03 <pgdir_walk>
f0102daa:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	ptep1 = KADDR(PTE_ADDR(boot_pgdir[PDX(va)]));
f0102dad:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102db2:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102db5:	c1 ea 16             	shr    $0x16,%edx
f0102db8:	c1 e2 02             	shl    $0x2,%edx
f0102dbb:	01 d0                	add    %edx,%eax
f0102dbd:	8b 00                	mov    (%eax),%eax
f0102dbf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102dc4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102dc7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102dca:	c1 e8 0c             	shr    $0xc,%eax
f0102dcd:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102dd0:	a1 20 7c 11 f0       	mov    0xf0117c20,%eax
f0102dd5:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f0102dd8:	72 23                	jb     f0102dfd <page_check+0xc3f>
f0102dda:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ddd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102de1:	c7 44 24 08 68 4b 10 	movl   $0xf0104b68,0x8(%esp)
f0102de8:	f0 
f0102de9:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f0102df0:	00 
f0102df1:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102df8:	e8 9f d2 ff ff       	call   f010009c <_panic>
f0102dfd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102e00:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102e05:	89 45 dc             	mov    %eax,-0x24(%ebp)
	assert(ptep == ptep1 + PTX(va));
f0102e08:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102e0b:	c1 e8 0c             	shr    $0xc,%eax
f0102e0e:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102e13:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0102e1a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102e1d:	01 c2                	add    %eax,%edx
f0102e1f:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0102e22:	39 c2                	cmp    %eax,%edx
f0102e24:	74 24                	je     f0102e4a <page_check+0xc8c>
f0102e26:	c7 44 24 0c c2 51 10 	movl   $0xf01051c2,0xc(%esp)
f0102e2d:	f0 
f0102e2e:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102e35:	f0 
f0102e36:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f0102e3d:	00 
f0102e3e:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102e45:	e8 52 d2 ff ff       	call   f010009c <_panic>
	boot_pgdir[PDX(va)] = 0;
f0102e4a:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102e4f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e52:	c1 ea 16             	shr    $0x16,%edx
f0102e55:	c1 e2 02             	shl    $0x2,%edx
f0102e58:	01 d0                	add    %edx,%eax
f0102e5a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102e60:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e63:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102e69:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e6c:	89 04 24             	mov    %eax,(%esp)
f0102e6f:	e8 ad de ff ff       	call   f0100d21 <page2kva>
f0102e74:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102e7b:	00 
f0102e7c:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102e83:	00 
f0102e84:	89 04 24             	mov    %eax,(%esp)
f0102e87:	e8 01 15 00 00       	call   f010438d <memset>
	page_free(pp0);
f0102e8c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e8f:	89 04 24             	mov    %eax,(%esp)
f0102e92:	e8 ea ee ff ff       	call   f0101d81 <page_free>
	pgdir_walk(boot_pgdir, 0x0, 1);
f0102e97:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102e9c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102ea3:	00 
f0102ea4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102eab:	00 
f0102eac:	89 04 24             	mov    %eax,(%esp)
f0102eaf:	e8 4f ef ff ff       	call   f0101e03 <pgdir_walk>
	ptep = page2kva(pp0);
f0102eb4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102eb7:	89 04 24             	mov    %eax,(%esp)
f0102eba:	e8 62 de ff ff       	call   f0100d21 <page2kva>
f0102ebf:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
f0102ec2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0102ec9:	eb 3c                	jmp    f0102f07 <page_check+0xd49>
		assert((ptep[i] & PTE_P) == 0);
f0102ecb:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0102ece:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102ed1:	c1 e2 02             	shl    $0x2,%edx
f0102ed4:	01 d0                	add    %edx,%eax
f0102ed6:	8b 00                	mov    (%eax),%eax
f0102ed8:	83 e0 01             	and    $0x1,%eax
f0102edb:	85 c0                	test   %eax,%eax
f0102edd:	74 24                	je     f0102f03 <page_check+0xd45>
f0102edf:	c7 44 24 0c da 51 10 	movl   $0xf01051da,0xc(%esp)
f0102ee6:	f0 
f0102ee7:	c7 44 24 08 12 4c 10 	movl   $0xf0104c12,0x8(%esp)
f0102eee:	f0 
f0102eef:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f0102ef6:	00 
f0102ef7:	c7 04 24 f0 4b 10 f0 	movl   $0xf0104bf0,(%esp)
f0102efe:	e8 99 d1 ff ff       	call   f010009c <_panic>
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(boot_pgdir, 0x0, 1);
	ptep = page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102f03:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
f0102f07:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
f0102f0e:	7e bb                	jle    f0102ecb <page_check+0xd0d>
		assert((ptep[i] & PTE_P) == 0);
	boot_pgdir[0] = 0;
f0102f10:	a1 28 7c 11 f0       	mov    0xf0117c28,%eax
f0102f15:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102f1b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102f1e:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)

	// give free list back
	page_free_list = fl;
f0102f24:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102f27:	a3 fc 77 11 f0       	mov    %eax,0xf01177fc

	// free the pages we took
	page_free(pp0);
f0102f2c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102f2f:	89 04 24             	mov    %eax,(%esp)
f0102f32:	e8 4a ee ff ff       	call   f0101d81 <page_free>
	page_free(pp1);
f0102f37:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102f3a:	89 04 24             	mov    %eax,(%esp)
f0102f3d:	e8 3f ee ff ff       	call   f0101d81 <page_free>
	page_free(pp2);
f0102f42:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102f45:	89 04 24             	mov    %eax,(%esp)
f0102f48:	e8 34 ee ff ff       	call   f0101d81 <page_free>
	
	cprintf("page_check() succeeded!\n");
f0102f4d:	c7 04 24 f1 51 10 f0 	movl   $0xf01051f1,(%esp)
f0102f54:	e8 af 05 00 00       	call   f0103508 <cprintf>
}
f0102f59:	83 c4 54             	add    $0x54,%esp
f0102f5c:	5b                   	pop    %ebx
f0102f5d:	5d                   	pop    %ebp
f0102f5e:	c3                   	ret    

f0102f5f <pa2page>:
	return page2ppn(pp) << PGSHIFT;
}

static inline struct Page*
pa2page(physaddr_t pa)
{
f0102f5f:	55                   	push   %ebp
f0102f60:	89 e5                	mov    %esp,%ebp
f0102f62:	83 ec 18             	sub    $0x18,%esp
	if (PPN(pa) >= npage)
f0102f65:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f68:	c1 e8 0c             	shr    $0xc,%eax
f0102f6b:	89 c2                	mov    %eax,%edx
f0102f6d:	a1 20 7c 11 f0       	mov    0xf0117c20,%eax
f0102f72:	39 c2                	cmp    %eax,%edx
f0102f74:	72 1c                	jb     f0102f92 <pa2page+0x33>
		panic("pa2page called with invalid pa");
f0102f76:	c7 44 24 08 0c 52 10 	movl   $0xf010520c,0x8(%esp)
f0102f7d:	f0 
f0102f7e:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0102f85:	00 
f0102f86:	c7 04 24 2b 52 10 f0 	movl   $0xf010522b,(%esp)
f0102f8d:	e8 0a d1 ff ff       	call   f010009c <_panic>
	return &pages[PPN(pa)];
f0102f92:	8b 0d 2c 7c 11 f0    	mov    0xf0117c2c,%ecx
f0102f98:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f9b:	c1 e8 0c             	shr    $0xc,%eax
f0102f9e:	89 c2                	mov    %eax,%edx
f0102fa0:	89 d0                	mov    %edx,%eax
f0102fa2:	01 c0                	add    %eax,%eax
f0102fa4:	01 d0                	add    %edx,%eax
f0102fa6:	c1 e0 02             	shl    $0x2,%eax
f0102fa9:	01 c8                	add    %ecx,%eax
}
f0102fab:	c9                   	leave  
f0102fac:	c3                   	ret    

f0102fad <envid2env>:
//   On success, sets *penv to the environment.
//   On error, sets *penv to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102fad:	55                   	push   %ebp
f0102fae:	89 e5                	mov    %esp,%ebp
f0102fb0:	83 ec 10             	sub    $0x10,%esp
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102fb3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0102fb7:	75 12                	jne    f0102fcb <envid2env+0x1e>
		*env_store = curenv;
f0102fb9:	8b 15 04 78 11 f0    	mov    0xf0117804,%edx
f0102fbf:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fc2:	89 10                	mov    %edx,(%eax)
		return 0;
f0102fc4:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fc9:	eb 7a                	jmp    f0103045 <envid2env+0x98>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102fcb:	8b 15 00 78 11 f0    	mov    0xf0117800,%edx
f0102fd1:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fd4:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102fd9:	6b c0 64             	imul   $0x64,%eax,%eax
f0102fdc:	01 d0                	add    %edx,%eax
f0102fde:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102fe1:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0102fe4:	8b 40 54             	mov    0x54(%eax),%eax
f0102fe7:	85 c0                	test   %eax,%eax
f0102fe9:	74 0b                	je     f0102ff6 <envid2env+0x49>
f0102feb:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0102fee:	8b 40 4c             	mov    0x4c(%eax),%eax
f0102ff1:	3b 45 08             	cmp    0x8(%ebp),%eax
f0102ff4:	74 10                	je     f0103006 <envid2env+0x59>
		*env_store = 0;
f0102ff6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ff9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102fff:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103004:	eb 3f                	jmp    f0103045 <envid2env+0x98>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103006:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010300a:	74 2c                	je     f0103038 <envid2env+0x8b>
f010300c:	a1 04 78 11 f0       	mov    0xf0117804,%eax
f0103011:	39 45 fc             	cmp    %eax,-0x4(%ebp)
f0103014:	74 22                	je     f0103038 <envid2env+0x8b>
f0103016:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0103019:	8b 50 50             	mov    0x50(%eax),%edx
f010301c:	a1 04 78 11 f0       	mov    0xf0117804,%eax
f0103021:	8b 40 4c             	mov    0x4c(%eax),%eax
f0103024:	39 c2                	cmp    %eax,%edx
f0103026:	74 10                	je     f0103038 <envid2env+0x8b>
		*env_store = 0;
f0103028:	8b 45 0c             	mov    0xc(%ebp),%eax
f010302b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103031:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103036:	eb 0d                	jmp    f0103045 <envid2env+0x98>
	}

	*env_store = e;
f0103038:	8b 45 0c             	mov    0xc(%ebp),%eax
f010303b:	8b 55 fc             	mov    -0x4(%ebp),%edx
f010303e:	89 10                	mov    %edx,(%eax)
	return 0;
f0103040:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103045:	c9                   	leave  
f0103046:	c3                   	ret    

f0103047 <env_init>:
// Insert in reverse order, so that the first call to env_alloc()
// returns envs[0].
//
void
env_init(void)
{
f0103047:	55                   	push   %ebp
f0103048:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f010304a:	5d                   	pop    %ebp
f010304b:	c3                   	ret    

f010304c <env_setup_vm>:
// Returns 0 on success, < 0 on error.  Errors include:
//	-E_NO_MEM if page directory or table could not be allocated.
//
static int
env_setup_vm(struct Env *e)
{
f010304c:	55                   	push   %ebp
f010304d:	89 e5                	mov    %esp,%ebp
f010304f:	83 ec 28             	sub    $0x28,%esp
	int i, r;
	struct Page *p = NULL;
f0103052:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

	// Allocate a page for the page directory
	if ((r = page_alloc(&p)) < 0)
f0103059:	8d 45 f0             	lea    -0x10(%ebp),%eax
f010305c:	89 04 24             	mov    %eax,(%esp)
f010305f:	e8 ca ec ff ff       	call   f0101d2e <page_alloc>
f0103064:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0103067:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f010306b:	79 05                	jns    f0103072 <env_setup_vm+0x26>
		return r;
f010306d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103070:	eb 33                	jmp    f01030a5 <env_setup_vm+0x59>

	// LAB 3: Your code here.

	// VPT and UVPT map the env's own page table, with
	// different permissions.
	e->env_pgdir[PDX(VPT)]  = e->env_cr3 | PTE_P | PTE_W;
f0103072:	8b 45 08             	mov    0x8(%ebp),%eax
f0103075:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103078:	8d 90 fc 0e 00 00    	lea    0xefc(%eax),%edx
f010307e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103081:	8b 40 60             	mov    0x60(%eax),%eax
f0103084:	83 c8 03             	or     $0x3,%eax
f0103087:	89 02                	mov    %eax,(%edx)
	e->env_pgdir[PDX(UVPT)] = e->env_cr3 | PTE_P | PTE_U;
f0103089:	8b 45 08             	mov    0x8(%ebp),%eax
f010308c:	8b 40 5c             	mov    0x5c(%eax),%eax
f010308f:	8d 90 f4 0e 00 00    	lea    0xef4(%eax),%edx
f0103095:	8b 45 08             	mov    0x8(%ebp),%eax
f0103098:	8b 40 60             	mov    0x60(%eax),%eax
f010309b:	83 c8 05             	or     $0x5,%eax
f010309e:	89 02                	mov    %eax,(%edx)

	return 0;
f01030a0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01030a5:	c9                   	leave  
f01030a6:	c3                   	ret    

f01030a7 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01030a7:	55                   	push   %ebp
f01030a8:	89 e5                	mov    %esp,%ebp
f01030aa:	83 ec 28             	sub    $0x28,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = LIST_FIRST(&env_free_list)))
f01030ad:	a1 08 78 11 f0       	mov    0xf0117808,%eax
f01030b2:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01030b5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f01030b9:	75 0a                	jne    f01030c5 <env_alloc+0x1e>
		return -E_NO_FREE_ENV;
f01030bb:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01030c0:	e9 28 01 00 00       	jmp    f01031ed <env_alloc+0x146>

	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
f01030c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01030c8:	89 04 24             	mov    %eax,(%esp)
f01030cb:	e8 7c ff ff ff       	call   f010304c <env_setup_vm>
f01030d0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01030d3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01030d7:	79 08                	jns    f01030e1 <env_alloc+0x3a>
		return r;
f01030d9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01030dc:	e9 0c 01 00 00       	jmp    f01031ed <env_alloc+0x146>

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01030e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01030e4:	8b 40 4c             	mov    0x4c(%eax),%eax
f01030e7:	05 00 10 00 00       	add    $0x1000,%eax
f01030ec:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01030f1:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (generation <= 0)	// Don't create a negative env_id.
f01030f4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f01030f8:	7f 07                	jg     f0103101 <env_alloc+0x5a>
		generation = 1 << ENVGENSHIFT;
f01030fa:	c7 45 f4 00 10 00 00 	movl   $0x1000,-0xc(%ebp)
	e->env_id = generation | (e - envs);
f0103101:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0103104:	a1 00 78 11 f0       	mov    0xf0117800,%eax
f0103109:	29 c2                	sub    %eax,%edx
f010310b:	89 d0                	mov    %edx,%eax
f010310d:	c1 f8 02             	sar    $0x2,%eax
f0103110:	69 c0 29 5c 8f c2    	imul   $0xc28f5c29,%eax,%eax
f0103116:	0b 45 f4             	or     -0xc(%ebp),%eax
f0103119:	89 c2                	mov    %eax,%edx
f010311b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010311e:	89 50 4c             	mov    %edx,0x4c(%eax)
	
	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103121:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103124:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103127:	89 50 50             	mov    %edx,0x50(%eax)
	e->env_status = ENV_RUNNABLE;
f010312a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010312d:	c7 40 54 01 00 00 00 	movl   $0x1,0x54(%eax)
	e->env_runs = 0;
f0103134:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103137:	c7 40 58 00 00 00 00 	movl   $0x0,0x58(%eax)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010313e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103141:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103148:	00 
f0103149:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103150:	00 
f0103151:	89 04 24             	mov    %eax,(%esp)
f0103154:	e8 34 12 00 00       	call   f010438d <memset>
	// Set up appropriate initial values for the segment registers.
	// GD_UD is the user data segment selector in the GDT, and 
	// GD_UT is the user text segment selector (see inc/memlayout.h).
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.
	e->env_tf.tf_ds = GD_UD | 3;
f0103159:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010315c:	66 c7 40 24 23 00    	movw   $0x23,0x24(%eax)
	e->env_tf.tf_es = GD_UD | 3;
f0103162:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103165:	66 c7 40 20 23 00    	movw   $0x23,0x20(%eax)
	e->env_tf.tf_ss = GD_UD | 3;
f010316b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010316e:	66 c7 40 40 23 00    	movw   $0x23,0x40(%eax)
	e->env_tf.tf_esp = USTACKTOP;
f0103174:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103177:	c7 40 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%eax)
	e->env_tf.tf_cs = GD_UT | 3;
f010317e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103181:	66 c7 40 34 1b 00    	movw   $0x1b,0x34(%eax)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	LIST_REMOVE(e, env_link);
f0103187:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010318a:	8b 40 44             	mov    0x44(%eax),%eax
f010318d:	85 c0                	test   %eax,%eax
f010318f:	74 0f                	je     f01031a0 <env_alloc+0xf9>
f0103191:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103194:	8b 40 44             	mov    0x44(%eax),%eax
f0103197:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010319a:	8b 52 48             	mov    0x48(%edx),%edx
f010319d:	89 50 48             	mov    %edx,0x48(%eax)
f01031a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01031a3:	8b 40 48             	mov    0x48(%eax),%eax
f01031a6:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01031a9:	8b 52 44             	mov    0x44(%edx),%edx
f01031ac:	89 10                	mov    %edx,(%eax)
	*newenv_store = e;
f01031ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01031b1:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01031b4:	89 10                	mov    %edx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01031b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01031b9:	8b 50 4c             	mov    0x4c(%eax),%edx
f01031bc:	a1 04 78 11 f0       	mov    0xf0117804,%eax
f01031c1:	85 c0                	test   %eax,%eax
f01031c3:	74 0a                	je     f01031cf <env_alloc+0x128>
f01031c5:	a1 04 78 11 f0       	mov    0xf0117804,%eax
f01031ca:	8b 40 4c             	mov    0x4c(%eax),%eax
f01031cd:	eb 05                	jmp    f01031d4 <env_alloc+0x12d>
f01031cf:	b8 00 00 00 00       	mov    $0x0,%eax
f01031d4:	89 54 24 08          	mov    %edx,0x8(%esp)
f01031d8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031dc:	c7 04 24 39 52 10 f0 	movl   $0xf0105239,(%esp)
f01031e3:	e8 20 03 00 00       	call   f0103508 <cprintf>
	return 0;
f01031e8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01031ed:	c9                   	leave  
f01031ee:	c3                   	ret    

f01031ef <segment_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
segment_alloc(struct Env *e, void *va, size_t len)
{
f01031ef:	55                   	push   %ebp
f01031f0:	89 e5                	mov    %esp,%ebp
	// (But only if you need it for load_icode.)
	//
	// Hint: It is easier to use segment_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round len up.
}
f01031f2:	5d                   	pop    %ebp
f01031f3:	c3                   	ret    

f01031f4 <load_icode>:
// load_icode panics if it encounters problems.
//  - How might load_icode fail?  What might be wrong with the given input?
//
static void
load_icode(struct Env *e, uint8_t *binary, size_t size)
{
f01031f4:	55                   	push   %ebp
f01031f5:	89 e5                	mov    %esp,%ebp

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
}
f01031f7:	5d                   	pop    %ebp
f01031f8:	c3                   	ret    

f01031f9 <env_create>:
// By convention, envs[0] is the first environment allocated, so
// whoever calls env_create simply looks for the newly created
// environment there. 
void
env_create(uint8_t *binary, size_t size)
{
f01031f9:	55                   	push   %ebp
f01031fa:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f01031fc:	5d                   	pop    %ebp
f01031fd:	c3                   	ret    

f01031fe <env_free>:
//
// Frees env e and all memory it uses.
// 
void
env_free(struct Env *e)
{
f01031fe:	55                   	push   %ebp
f01031ff:	89 e5                	mov    %esp,%ebp
f0103201:	83 ec 38             	sub    $0x38,%esp
	physaddr_t pa;
	
	// If freeing the current environment, switch to boot_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103204:	a1 04 78 11 f0       	mov    0xf0117804,%eax
f0103209:	39 45 08             	cmp    %eax,0x8(%ebp)
f010320c:	75 0e                	jne    f010321c <env_free+0x1e>
		lcr3(boot_cr3);
f010320e:	a1 24 7c 11 f0       	mov    0xf0117c24,%eax
f0103213:	89 45 dc             	mov    %eax,-0x24(%ebp)
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103216:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103219:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010321c:	8b 45 08             	mov    0x8(%ebp),%eax
f010321f:	8b 50 4c             	mov    0x4c(%eax),%edx
f0103222:	a1 04 78 11 f0       	mov    0xf0117804,%eax
f0103227:	85 c0                	test   %eax,%eax
f0103229:	74 0a                	je     f0103235 <env_free+0x37>
f010322b:	a1 04 78 11 f0       	mov    0xf0117804,%eax
f0103230:	8b 40 4c             	mov    0x4c(%eax),%eax
f0103233:	eb 05                	jmp    f010323a <env_free+0x3c>
f0103235:	b8 00 00 00 00       	mov    $0x0,%eax
f010323a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010323e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103242:	c7 04 24 4e 52 10 f0 	movl   $0xf010524e,(%esp)
f0103249:	e8 ba 02 00 00       	call   f0103508 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010324e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0103255:	e9 f8 00 00 00       	jmp    f0103352 <env_free+0x154>

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010325a:	8b 45 08             	mov    0x8(%ebp),%eax
f010325d:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103260:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103263:	c1 e2 02             	shl    $0x2,%edx
f0103266:	01 d0                	add    %edx,%eax
f0103268:	8b 00                	mov    (%eax),%eax
f010326a:	83 e0 01             	and    $0x1,%eax
f010326d:	85 c0                	test   %eax,%eax
f010326f:	75 05                	jne    f0103276 <env_free+0x78>
			continue;
f0103271:	e9 d8 00 00 00       	jmp    f010334e <env_free+0x150>

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103276:	8b 45 08             	mov    0x8(%ebp),%eax
f0103279:	8b 40 5c             	mov    0x5c(%eax),%eax
f010327c:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010327f:	c1 e2 02             	shl    $0x2,%edx
f0103282:	01 d0                	add    %edx,%eax
f0103284:	8b 00                	mov    (%eax),%eax
f0103286:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010328b:	89 45 ec             	mov    %eax,-0x14(%ebp)
		pt = (pte_t*) KADDR(pa);
f010328e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103291:	89 45 e8             	mov    %eax,-0x18(%ebp)
f0103294:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103297:	c1 e8 0c             	shr    $0xc,%eax
f010329a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010329d:	a1 20 7c 11 f0       	mov    0xf0117c20,%eax
f01032a2:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01032a5:	72 23                	jb     f01032ca <env_free+0xcc>
f01032a7:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01032aa:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01032ae:	c7 44 24 08 64 52 10 	movl   $0xf0105264,0x8(%esp)
f01032b5:	f0 
f01032b6:	c7 44 24 04 32 01 00 	movl   $0x132,0x4(%esp)
f01032bd:	00 
f01032be:	c7 04 24 87 52 10 f0 	movl   $0xf0105287,(%esp)
f01032c5:	e8 d2 cd ff ff       	call   f010009c <_panic>
f01032ca:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01032cd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01032d2:	89 45 e0             	mov    %eax,-0x20(%ebp)

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01032d5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f01032dc:	eb 40                	jmp    f010331e <env_free+0x120>
			if (pt[pteno] & PTE_P)
f01032de:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01032e1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01032e8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032eb:	01 d0                	add    %edx,%eax
f01032ed:	8b 00                	mov    (%eax),%eax
f01032ef:	83 e0 01             	and    $0x1,%eax
f01032f2:	85 c0                	test   %eax,%eax
f01032f4:	74 24                	je     f010331a <env_free+0x11c>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01032f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01032f9:	c1 e0 16             	shl    $0x16,%eax
f01032fc:	89 c2                	mov    %eax,%edx
f01032fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103301:	c1 e0 0c             	shl    $0xc,%eax
f0103304:	09 d0                	or     %edx,%eax
f0103306:	89 c2                	mov    %eax,%edx
f0103308:	8b 45 08             	mov    0x8(%ebp),%eax
f010330b:	8b 40 5c             	mov    0x5c(%eax),%eax
f010330e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103312:	89 04 24             	mov    %eax,(%esp)
f0103315:	e8 39 ee ff ff       	call   f0102153 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010331a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
f010331e:	81 7d f0 ff 03 00 00 	cmpl   $0x3ff,-0x10(%ebp)
f0103325:	76 b7                	jbe    f01032de <env_free+0xe0>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103327:	8b 45 08             	mov    0x8(%ebp),%eax
f010332a:	8b 40 5c             	mov    0x5c(%eax),%eax
f010332d:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103330:	c1 e2 02             	shl    $0x2,%edx
f0103333:	01 d0                	add    %edx,%eax
f0103335:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		page_decref(pa2page(pa));
f010333b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010333e:	89 04 24             	mov    %eax,(%esp)
f0103341:	e8 19 fc ff ff       	call   f0102f5f <pa2page>
f0103346:	89 04 24             	mov    %eax,(%esp)
f0103349:	e8 85 ea ff ff       	call   f0101dd3 <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010334e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
f0103352:	81 7d f4 ba 03 00 00 	cmpl   $0x3ba,-0xc(%ebp)
f0103359:	0f 86 fb fe ff ff    	jbe    f010325a <env_free+0x5c>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = e->env_cr3;
f010335f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103362:	8b 40 60             	mov    0x60(%eax),%eax
f0103365:	89 45 ec             	mov    %eax,-0x14(%ebp)
	e->env_pgdir = 0;
f0103368:	8b 45 08             	mov    0x8(%ebp),%eax
f010336b:	c7 40 5c 00 00 00 00 	movl   $0x0,0x5c(%eax)
	e->env_cr3 = 0;
f0103372:	8b 45 08             	mov    0x8(%ebp),%eax
f0103375:	c7 40 60 00 00 00 00 	movl   $0x0,0x60(%eax)
	page_decref(pa2page(pa));
f010337c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010337f:	89 04 24             	mov    %eax,(%esp)
f0103382:	e8 d8 fb ff ff       	call   f0102f5f <pa2page>
f0103387:	89 04 24             	mov    %eax,(%esp)
f010338a:	e8 44 ea ff ff       	call   f0101dd3 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f010338f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103392:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	LIST_INSERT_HEAD(&env_free_list, e, env_link);
f0103399:	8b 15 08 78 11 f0    	mov    0xf0117808,%edx
f010339f:	8b 45 08             	mov    0x8(%ebp),%eax
f01033a2:	89 50 44             	mov    %edx,0x44(%eax)
f01033a5:	8b 45 08             	mov    0x8(%ebp),%eax
f01033a8:	8b 40 44             	mov    0x44(%eax),%eax
f01033ab:	85 c0                	test   %eax,%eax
f01033ad:	74 0e                	je     f01033bd <env_free+0x1bf>
f01033af:	a1 08 78 11 f0       	mov    0xf0117808,%eax
f01033b4:	8b 55 08             	mov    0x8(%ebp),%edx
f01033b7:	83 c2 44             	add    $0x44,%edx
f01033ba:	89 50 48             	mov    %edx,0x48(%eax)
f01033bd:	8b 45 08             	mov    0x8(%ebp),%eax
f01033c0:	a3 08 78 11 f0       	mov    %eax,0xf0117808
f01033c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01033c8:	c7 40 48 08 78 11 f0 	movl   $0xf0117808,0x48(%eax)
}
f01033cf:	c9                   	leave  
f01033d0:	c3                   	ret    

f01033d1 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e) 
{
f01033d1:	55                   	push   %ebp
f01033d2:	89 e5                	mov    %esp,%ebp
f01033d4:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f01033d7:	8b 45 08             	mov    0x8(%ebp),%eax
f01033da:	89 04 24             	mov    %eax,(%esp)
f01033dd:	e8 1c fe ff ff       	call   f01031fe <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f01033e2:	c7 04 24 94 52 10 f0 	movl   $0xf0105294,(%esp)
f01033e9:	e8 1a 01 00 00       	call   f0103508 <cprintf>
	while (1)
		monitor(NULL);
f01033ee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01033f5:	e8 49 d8 ff ff       	call   f0100c43 <monitor>
f01033fa:	eb f2                	jmp    f01033ee <env_destroy+0x1d>

f01033fc <env_pop_tf>:
// This exits the kernel and starts executing some environment's code.
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01033fc:	55                   	push   %ebp
f01033fd:	89 e5                	mov    %esp,%ebp
f01033ff:	83 ec 18             	sub    $0x18,%esp
	__asm __volatile("movl %0,%%esp\n"
f0103402:	8b 65 08             	mov    0x8(%ebp),%esp
f0103405:	61                   	popa   
f0103406:	07                   	pop    %es
f0103407:	1f                   	pop    %ds
f0103408:	83 c4 08             	add    $0x8,%esp
f010340b:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f010340c:	c7 44 24 08 ca 52 10 	movl   $0xf01052ca,0x8(%esp)
f0103413:	f0 
f0103414:	c7 44 24 04 69 01 00 	movl   $0x169,0x4(%esp)
f010341b:	00 
f010341c:	c7 04 24 87 52 10 f0 	movl   $0xf0105287,(%esp)
f0103423:	e8 74 cc ff ff       	call   f010009c <_panic>

f0103428 <env_run>:
// Note: if this is the first call to env_run, curenv is NULL.
//  (This function does not return.)
//
void
env_run(struct Env *e)
{
f0103428:	55                   	push   %ebp
f0103429:	89 e5                	mov    %esp,%ebp
f010342b:	83 ec 18             	sub    $0x18,%esp
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.
	
	// LAB 3: Your code here.

        panic("env_run not yet implemented");
f010342e:	c7 44 24 08 d6 52 10 	movl   $0xf01052d6,0x8(%esp)
f0103435:	f0 
f0103436:	c7 44 24 04 83 01 00 	movl   $0x183,0x4(%esp)
f010343d:	00 
f010343e:	c7 04 24 87 52 10 f0 	movl   $0xf0105287,(%esp)
f0103445:	e8 52 cc ff ff       	call   f010009c <_panic>

f010344a <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010344a:	55                   	push   %ebp
f010344b:	89 e5                	mov    %esp,%ebp
f010344d:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
f0103450:	8b 45 08             	mov    0x8(%ebp),%eax
f0103453:	0f b6 c0             	movzbl %al,%eax
f0103456:	c7 45 fc 70 00 00 00 	movl   $0x70,-0x4(%ebp)
f010345d:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103460:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
f0103464:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0103467:	ee                   	out    %al,(%dx)
f0103468:	c7 45 f4 71 00 00 00 	movl   $0x71,-0xc(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010346f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103472:	89 c2                	mov    %eax,%edx
f0103474:	ec                   	in     (%dx),%al
f0103475:	88 45 f3             	mov    %al,-0xd(%ebp)
	return data;
f0103478:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
	return inb(IO_RTC+1);
f010347c:	0f b6 c0             	movzbl %al,%eax
}
f010347f:	c9                   	leave  
f0103480:	c3                   	ret    

f0103481 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103481:	55                   	push   %ebp
f0103482:	89 e5                	mov    %esp,%ebp
f0103484:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
f0103487:	8b 45 08             	mov    0x8(%ebp),%eax
f010348a:	0f b6 c0             	movzbl %al,%eax
f010348d:	c7 45 fc 70 00 00 00 	movl   $0x70,-0x4(%ebp)
f0103494:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103497:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
f010349b:	8b 55 fc             	mov    -0x4(%ebp),%edx
f010349e:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
f010349f:	8b 45 0c             	mov    0xc(%ebp),%eax
f01034a2:	0f b6 c0             	movzbl %al,%eax
f01034a5:	c7 45 f4 71 00 00 00 	movl   $0x71,-0xc(%ebp)
f01034ac:	88 45 f3             	mov    %al,-0xd(%ebp)
f01034af:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f01034b3:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01034b6:	ee                   	out    %al,(%dx)
}
f01034b7:	c9                   	leave  
f01034b8:	c3                   	ret    

f01034b9 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01034b9:	55                   	push   %ebp
f01034ba:	89 e5                	mov    %esp,%ebp
f01034bc:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01034bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01034c2:	89 04 24             	mov    %eax,(%esp)
f01034c5:	e8 e6 d3 ff ff       	call   f01008b0 <cputchar>
	*cnt++;
f01034ca:	8b 45 0c             	mov    0xc(%ebp),%eax
f01034cd:	83 c0 04             	add    $0x4,%eax
f01034d0:	89 45 0c             	mov    %eax,0xc(%ebp)
}
f01034d3:	c9                   	leave  
f01034d4:	c3                   	ret    

f01034d5 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01034d5:	55                   	push   %ebp
f01034d6:	89 e5                	mov    %esp,%ebp
f01034d8:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01034db:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01034e2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01034e5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01034ec:	89 44 24 08          	mov    %eax,0x8(%esp)
f01034f0:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01034f3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034f7:	c7 04 24 b9 34 10 f0 	movl   $0xf01034b9,(%esp)
f01034fe:	e8 8a 06 00 00       	call   f0103b8d <vprintfmt>
	return cnt;
f0103503:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0103506:	c9                   	leave  
f0103507:	c3                   	ret    

f0103508 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103508:	55                   	push   %ebp
f0103509:	89 e5                	mov    %esp,%ebp
f010350b:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010350e:	8d 45 0c             	lea    0xc(%ebp),%eax
f0103511:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
f0103514:	8b 45 08             	mov    0x8(%ebp),%eax
f0103517:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010351a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010351e:	89 04 24             	mov    %eax,(%esp)
f0103521:	e8 af ff ff ff       	call   f01034d5 <vcprintf>
f0103526:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
f0103529:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
f010352c:	c9                   	leave  
f010352d:	c3                   	ret    

f010352e <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010352e:	55                   	push   %ebp
f010352f:	89 e5                	mov    %esp,%ebp
f0103531:	83 ec 20             	sub    $0x20,%esp
	int l = *region_left, r = *region_right, any_matches = 0;
f0103534:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103537:	8b 00                	mov    (%eax),%eax
f0103539:	89 45 fc             	mov    %eax,-0x4(%ebp)
f010353c:	8b 45 10             	mov    0x10(%ebp),%eax
f010353f:	8b 00                	mov    (%eax),%eax
f0103541:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0103544:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	
	while (l <= r) {
f010354b:	e9 d2 00 00 00       	jmp    f0103622 <stab_binsearch+0xf4>
		int true_m = (l + r) / 2, m = true_m;
f0103550:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0103553:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0103556:	01 d0                	add    %edx,%eax
f0103558:	89 c2                	mov    %eax,%edx
f010355a:	c1 ea 1f             	shr    $0x1f,%edx
f010355d:	01 d0                	add    %edx,%eax
f010355f:	d1 f8                	sar    %eax
f0103561:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103564:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103567:	89 45 f0             	mov    %eax,-0x10(%ebp)
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010356a:	eb 04                	jmp    f0103570 <stab_binsearch+0x42>
			m--;
f010356c:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103570:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103573:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0103576:	7c 1f                	jl     f0103597 <stab_binsearch+0x69>
f0103578:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010357b:	89 d0                	mov    %edx,%eax
f010357d:	01 c0                	add    %eax,%eax
f010357f:	01 d0                	add    %edx,%eax
f0103581:	c1 e0 02             	shl    $0x2,%eax
f0103584:	89 c2                	mov    %eax,%edx
f0103586:	8b 45 08             	mov    0x8(%ebp),%eax
f0103589:	01 d0                	add    %edx,%eax
f010358b:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f010358f:	0f b6 c0             	movzbl %al,%eax
f0103592:	3b 45 14             	cmp    0x14(%ebp),%eax
f0103595:	75 d5                	jne    f010356c <stab_binsearch+0x3e>
			m--;
		if (m < l) {	// no match in [l, m]
f0103597:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010359a:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f010359d:	7d 0b                	jge    f01035aa <stab_binsearch+0x7c>
			l = true_m + 1;
f010359f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01035a2:	83 c0 01             	add    $0x1,%eax
f01035a5:	89 45 fc             	mov    %eax,-0x4(%ebp)
			continue;
f01035a8:	eb 78                	jmp    f0103622 <stab_binsearch+0xf4>
		}

		// actual binary search
		any_matches = 1;
f01035aa:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
		if (stabs[m].n_value < addr) {
f01035b1:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01035b4:	89 d0                	mov    %edx,%eax
f01035b6:	01 c0                	add    %eax,%eax
f01035b8:	01 d0                	add    %edx,%eax
f01035ba:	c1 e0 02             	shl    $0x2,%eax
f01035bd:	89 c2                	mov    %eax,%edx
f01035bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01035c2:	01 d0                	add    %edx,%eax
f01035c4:	8b 40 08             	mov    0x8(%eax),%eax
f01035c7:	3b 45 18             	cmp    0x18(%ebp),%eax
f01035ca:	73 13                	jae    f01035df <stab_binsearch+0xb1>
			*region_left = m;
f01035cc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035cf:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01035d2:	89 10                	mov    %edx,(%eax)
			l = true_m + 1;
f01035d4:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01035d7:	83 c0 01             	add    $0x1,%eax
f01035da:	89 45 fc             	mov    %eax,-0x4(%ebp)
f01035dd:	eb 43                	jmp    f0103622 <stab_binsearch+0xf4>
		} else if (stabs[m].n_value > addr) {
f01035df:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01035e2:	89 d0                	mov    %edx,%eax
f01035e4:	01 c0                	add    %eax,%eax
f01035e6:	01 d0                	add    %edx,%eax
f01035e8:	c1 e0 02             	shl    $0x2,%eax
f01035eb:	89 c2                	mov    %eax,%edx
f01035ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01035f0:	01 d0                	add    %edx,%eax
f01035f2:	8b 40 08             	mov    0x8(%eax),%eax
f01035f5:	3b 45 18             	cmp    0x18(%ebp),%eax
f01035f8:	76 16                	jbe    f0103610 <stab_binsearch+0xe2>
			*region_right = m - 1;
f01035fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01035fd:	8d 50 ff             	lea    -0x1(%eax),%edx
f0103600:	8b 45 10             	mov    0x10(%ebp),%eax
f0103603:	89 10                	mov    %edx,(%eax)
			r = m - 1;
f0103605:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103608:	83 e8 01             	sub    $0x1,%eax
f010360b:	89 45 f8             	mov    %eax,-0x8(%ebp)
f010360e:	eb 12                	jmp    f0103622 <stab_binsearch+0xf4>
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103610:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103613:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0103616:	89 10                	mov    %edx,(%eax)
			l = m;
f0103618:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010361b:	89 45 fc             	mov    %eax,-0x4(%ebp)
			addr++;
f010361e:	83 45 18 01          	addl   $0x1,0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0103622:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0103625:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f0103628:	0f 8e 22 ff ff ff    	jle    f0103550 <stab_binsearch+0x22>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010362e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0103632:	75 0f                	jne    f0103643 <stab_binsearch+0x115>
		*region_right = *region_left - 1;
f0103634:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103637:	8b 00                	mov    (%eax),%eax
f0103639:	8d 50 ff             	lea    -0x1(%eax),%edx
f010363c:	8b 45 10             	mov    0x10(%ebp),%eax
f010363f:	89 10                	mov    %edx,(%eax)
f0103641:	eb 3f                	jmp    f0103682 <stab_binsearch+0x154>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103643:	8b 45 10             	mov    0x10(%ebp),%eax
f0103646:	8b 00                	mov    (%eax),%eax
f0103648:	89 45 fc             	mov    %eax,-0x4(%ebp)
f010364b:	eb 04                	jmp    f0103651 <stab_binsearch+0x123>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010364d:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0103651:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103654:	8b 00                	mov    (%eax),%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103656:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0103659:	7d 1f                	jge    f010367a <stab_binsearch+0x14c>
		     l > *region_left && stabs[l].n_type != type;
f010365b:	8b 55 fc             	mov    -0x4(%ebp),%edx
f010365e:	89 d0                	mov    %edx,%eax
f0103660:	01 c0                	add    %eax,%eax
f0103662:	01 d0                	add    %edx,%eax
f0103664:	c1 e0 02             	shl    $0x2,%eax
f0103667:	89 c2                	mov    %eax,%edx
f0103669:	8b 45 08             	mov    0x8(%ebp),%eax
f010366c:	01 d0                	add    %edx,%eax
f010366e:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f0103672:	0f b6 c0             	movzbl %al,%eax
f0103675:	3b 45 14             	cmp    0x14(%ebp),%eax
f0103678:	75 d3                	jne    f010364d <stab_binsearch+0x11f>
		     l--)
			/* do nothing */;
		*region_left = l;
f010367a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010367d:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0103680:	89 10                	mov    %edx,(%eax)
	}
}
f0103682:	c9                   	leave  
f0103683:	c3                   	ret    

f0103684 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103684:	55                   	push   %ebp
f0103685:	89 e5                	mov    %esp,%ebp
f0103687:	83 ec 58             	sub    $0x58,%esp
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010368a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010368d:	c7 00 f2 52 10 f0    	movl   $0xf01052f2,(%eax)
	info->eip_line = 0;
f0103693:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103696:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	info->eip_fn_name = "<unknown>";
f010369d:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036a0:	c7 40 08 f2 52 10 f0 	movl   $0xf01052f2,0x8(%eax)
	info->eip_fn_namelen = 9;
f01036a7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036aa:	c7 40 0c 09 00 00 00 	movl   $0x9,0xc(%eax)
	info->eip_fn_addr = addr;
f01036b1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036b4:	8b 55 08             	mov    0x8(%ebp),%edx
f01036b7:	89 50 10             	mov    %edx,0x10(%eax)
	info->eip_fn_narg = 0;
f01036ba:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036bd:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01036c4:	81 7d 08 ff ff 7f ef 	cmpl   $0xef7fffff,0x8(%ebp)
f01036cb:	76 26                	jbe    f01036f3 <debuginfo_eip+0x6f>
		stabs = __STAB_BEGIN__;
f01036cd:	c7 45 f4 30 55 10 f0 	movl   $0xf0105530,-0xc(%ebp)
		stab_end = __STAB_END__;
f01036d4:	c7 45 f0 20 bf 10 f0 	movl   $0xf010bf20,-0x10(%ebp)
		stabstr = __STABSTR_BEGIN__;
f01036db:	c7 45 ec 21 bf 10 f0 	movl   $0xf010bf21,-0x14(%ebp)
		stabstr_end = __STABSTR_END__;
f01036e2:	c7 45 e8 c1 e5 10 f0 	movl   $0xf010e5c1,-0x18(%ebp)
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01036e9:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01036ec:	3b 45 ec             	cmp    -0x14(%ebp),%eax
f01036ef:	76 2b                	jbe    f010371c <debuginfo_eip+0x98>
f01036f1:	eb 1c                	jmp    f010370f <debuginfo_eip+0x8b>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01036f3:	c7 44 24 08 fc 52 10 	movl   $0xf01052fc,0x8(%esp)
f01036fa:	f0 
f01036fb:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
f0103702:	00 
f0103703:	c7 04 24 09 53 10 f0 	movl   $0xf0105309,(%esp)
f010370a:	e8 8d c9 ff ff       	call   f010009c <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010370f:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103712:	83 e8 01             	sub    $0x1,%eax
f0103715:	0f b6 00             	movzbl (%eax),%eax
f0103718:	84 c0                	test   %al,%al
f010371a:	74 0a                	je     f0103726 <debuginfo_eip+0xa2>
		return -1;
f010371c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103721:	e9 c1 02 00 00       	jmp    f01039e7 <debuginfo_eip+0x363>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103726:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010372d:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0103730:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103733:	29 c2                	sub    %eax,%edx
f0103735:	89 d0                	mov    %edx,%eax
f0103737:	c1 f8 02             	sar    $0x2,%eax
f010373a:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103740:	83 e8 01             	sub    $0x1,%eax
f0103743:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103746:	8b 45 08             	mov    0x8(%ebp),%eax
f0103749:	89 44 24 10          	mov    %eax,0x10(%esp)
f010374d:	c7 44 24 0c 64 00 00 	movl   $0x64,0xc(%esp)
f0103754:	00 
f0103755:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0103758:	89 44 24 08          	mov    %eax,0x8(%esp)
f010375c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010375f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103763:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103766:	89 04 24             	mov    %eax,(%esp)
f0103769:	e8 c0 fd ff ff       	call   f010352e <stab_binsearch>
	if (lfile == 0)
f010376e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103771:	85 c0                	test   %eax,%eax
f0103773:	75 0a                	jne    f010377f <debuginfo_eip+0xfb>
		return -1;
f0103775:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010377a:	e9 68 02 00 00       	jmp    f01039e7 <debuginfo_eip+0x363>

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010377f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103782:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103785:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103788:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010378b:	8b 45 08             	mov    0x8(%ebp),%eax
f010378e:	89 44 24 10          	mov    %eax,0x10(%esp)
f0103792:	c7 44 24 0c 24 00 00 	movl   $0x24,0xc(%esp)
f0103799:	00 
f010379a:	8d 45 d8             	lea    -0x28(%ebp),%eax
f010379d:	89 44 24 08          	mov    %eax,0x8(%esp)
f01037a1:	8d 45 dc             	lea    -0x24(%ebp),%eax
f01037a4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01037ab:	89 04 24             	mov    %eax,(%esp)
f01037ae:	e8 7b fd ff ff       	call   f010352e <stab_binsearch>

	if (lfun <= rfun) {
f01037b3:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01037b6:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01037b9:	39 c2                	cmp    %eax,%edx
f01037bb:	7f 7c                	jg     f0103839 <debuginfo_eip+0x1b5>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01037bd:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01037c0:	89 c2                	mov    %eax,%edx
f01037c2:	89 d0                	mov    %edx,%eax
f01037c4:	01 c0                	add    %eax,%eax
f01037c6:	01 d0                	add    %edx,%eax
f01037c8:	c1 e0 02             	shl    $0x2,%eax
f01037cb:	89 c2                	mov    %eax,%edx
f01037cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01037d0:	01 d0                	add    %edx,%eax
f01037d2:	8b 10                	mov    (%eax),%edx
f01037d4:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f01037d7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01037da:	29 c1                	sub    %eax,%ecx
f01037dc:	89 c8                	mov    %ecx,%eax
f01037de:	39 c2                	cmp    %eax,%edx
f01037e0:	73 22                	jae    f0103804 <debuginfo_eip+0x180>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01037e2:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01037e5:	89 c2                	mov    %eax,%edx
f01037e7:	89 d0                	mov    %edx,%eax
f01037e9:	01 c0                	add    %eax,%eax
f01037eb:	01 d0                	add    %edx,%eax
f01037ed:	c1 e0 02             	shl    $0x2,%eax
f01037f0:	89 c2                	mov    %eax,%edx
f01037f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01037f5:	01 d0                	add    %edx,%eax
f01037f7:	8b 10                	mov    (%eax),%edx
f01037f9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01037fc:	01 c2                	add    %eax,%edx
f01037fe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103801:	89 50 08             	mov    %edx,0x8(%eax)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103804:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103807:	89 c2                	mov    %eax,%edx
f0103809:	89 d0                	mov    %edx,%eax
f010380b:	01 c0                	add    %eax,%eax
f010380d:	01 d0                	add    %edx,%eax
f010380f:	c1 e0 02             	shl    $0x2,%eax
f0103812:	89 c2                	mov    %eax,%edx
f0103814:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103817:	01 d0                	add    %edx,%eax
f0103819:	8b 50 08             	mov    0x8(%eax),%edx
f010381c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010381f:	89 50 10             	mov    %edx,0x10(%eax)
		addr -= info->eip_fn_addr;
f0103822:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103825:	8b 40 10             	mov    0x10(%eax),%eax
f0103828:	29 45 08             	sub    %eax,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f010382b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010382e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103831:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103834:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103837:	eb 15                	jmp    f010384e <debuginfo_eip+0x1ca>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103839:	8b 45 0c             	mov    0xc(%ebp),%eax
f010383c:	8b 55 08             	mov    0x8(%ebp),%edx
f010383f:	89 50 10             	mov    %edx,0x10(%eax)
		lline = lfile;
f0103842:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103845:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103848:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010384b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010384e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103851:	8b 40 08             	mov    0x8(%eax),%eax
f0103854:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f010385b:	00 
f010385c:	89 04 24             	mov    %eax,(%esp)
f010385f:	e8 fb 0a 00 00       	call   f010435f <strfind>
f0103864:	89 c2                	mov    %eax,%edx
f0103866:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103869:	8b 40 08             	mov    0x8(%eax),%eax
f010386c:	29 c2                	sub    %eax,%edx
f010386e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103871:	89 50 0c             	mov    %edx,0xc(%eax)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs,&lline,&rline,N_SLINE,addr);
f0103874:	8b 45 08             	mov    0x8(%ebp),%eax
f0103877:	89 44 24 10          	mov    %eax,0x10(%esp)
f010387b:	c7 44 24 0c 44 00 00 	movl   $0x44,0xc(%esp)
f0103882:	00 
f0103883:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0103886:	89 44 24 08          	mov    %eax,0x8(%esp)
f010388a:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f010388d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103891:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103894:	89 04 24             	mov    %eax,(%esp)
f0103897:	e8 92 fc ff ff       	call   f010352e <stab_binsearch>
	if (lline<=rline)
f010389c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010389f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01038a2:	39 c2                	cmp    %eax,%edx
f01038a4:	7f 24                	jg     f01038ca <debuginfo_eip+0x246>
	{
		info->eip_line=stabs[lline].n_desc;
f01038a6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01038a9:	89 c2                	mov    %eax,%edx
f01038ab:	89 d0                	mov    %edx,%eax
f01038ad:	01 c0                	add    %eax,%eax
f01038af:	01 d0                	add    %edx,%eax
f01038b1:	c1 e0 02             	shl    $0x2,%eax
f01038b4:	89 c2                	mov    %eax,%edx
f01038b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01038b9:	01 d0                	add    %edx,%eax
f01038bb:	0f b7 40 06          	movzwl 0x6(%eax),%eax
f01038bf:	0f b7 d0             	movzwl %ax,%edx
f01038c2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038c5:	89 50 04             	mov    %edx,0x4(%eax)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01038c8:	eb 1d                	jmp    f01038e7 <debuginfo_eip+0x263>
	if (lline<=rline)
	{
		info->eip_line=stabs[lline].n_desc;
	}else
	{
		info->eip_line=0;
f01038ca:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038cd:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
		return -1;
f01038d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01038d9:	e9 09 01 00 00       	jmp    f01039e7 <debuginfo_eip+0x363>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01038de:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01038e1:	83 e8 01             	sub    $0x1,%eax
f01038e4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01038e7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01038ea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01038ed:	39 c2                	cmp    %eax,%edx
f01038ef:	7c 56                	jl     f0103947 <debuginfo_eip+0x2c3>
	       && stabs[lline].n_type != N_SOL
f01038f1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01038f4:	89 c2                	mov    %eax,%edx
f01038f6:	89 d0                	mov    %edx,%eax
f01038f8:	01 c0                	add    %eax,%eax
f01038fa:	01 d0                	add    %edx,%eax
f01038fc:	c1 e0 02             	shl    $0x2,%eax
f01038ff:	89 c2                	mov    %eax,%edx
f0103901:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103904:	01 d0                	add    %edx,%eax
f0103906:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f010390a:	3c 84                	cmp    $0x84,%al
f010390c:	74 39                	je     f0103947 <debuginfo_eip+0x2c3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010390e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103911:	89 c2                	mov    %eax,%edx
f0103913:	89 d0                	mov    %edx,%eax
f0103915:	01 c0                	add    %eax,%eax
f0103917:	01 d0                	add    %edx,%eax
f0103919:	c1 e0 02             	shl    $0x2,%eax
f010391c:	89 c2                	mov    %eax,%edx
f010391e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103921:	01 d0                	add    %edx,%eax
f0103923:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f0103927:	3c 64                	cmp    $0x64,%al
f0103929:	75 b3                	jne    f01038de <debuginfo_eip+0x25a>
f010392b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010392e:	89 c2                	mov    %eax,%edx
f0103930:	89 d0                	mov    %edx,%eax
f0103932:	01 c0                	add    %eax,%eax
f0103934:	01 d0                	add    %edx,%eax
f0103936:	c1 e0 02             	shl    $0x2,%eax
f0103939:	89 c2                	mov    %eax,%edx
f010393b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010393e:	01 d0                	add    %edx,%eax
f0103940:	8b 40 08             	mov    0x8(%eax),%eax
f0103943:	85 c0                	test   %eax,%eax
f0103945:	74 97                	je     f01038de <debuginfo_eip+0x25a>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103947:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010394a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010394d:	39 c2                	cmp    %eax,%edx
f010394f:	7c 46                	jl     f0103997 <debuginfo_eip+0x313>
f0103951:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103954:	89 c2                	mov    %eax,%edx
f0103956:	89 d0                	mov    %edx,%eax
f0103958:	01 c0                	add    %eax,%eax
f010395a:	01 d0                	add    %edx,%eax
f010395c:	c1 e0 02             	shl    $0x2,%eax
f010395f:	89 c2                	mov    %eax,%edx
f0103961:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103964:	01 d0                	add    %edx,%eax
f0103966:	8b 10                	mov    (%eax),%edx
f0103968:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f010396b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010396e:	29 c1                	sub    %eax,%ecx
f0103970:	89 c8                	mov    %ecx,%eax
f0103972:	39 c2                	cmp    %eax,%edx
f0103974:	73 21                	jae    f0103997 <debuginfo_eip+0x313>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103976:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103979:	89 c2                	mov    %eax,%edx
f010397b:	89 d0                	mov    %edx,%eax
f010397d:	01 c0                	add    %eax,%eax
f010397f:	01 d0                	add    %edx,%eax
f0103981:	c1 e0 02             	shl    $0x2,%eax
f0103984:	89 c2                	mov    %eax,%edx
f0103986:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103989:	01 d0                	add    %edx,%eax
f010398b:	8b 10                	mov    (%eax),%edx
f010398d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103990:	01 c2                	add    %eax,%edx
f0103992:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103995:	89 10                	mov    %edx,(%eax)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	// Your code here.
	info->eip_fn_narg=0;
f0103997:	8b 45 0c             	mov    0xc(%ebp),%eax
f010399a:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
	while (lfun<=rfun)
f01039a1:	eb 35                	jmp    f01039d8 <debuginfo_eip+0x354>
	{
		if (stabs[lfun].n_type== N_PSYM)
f01039a3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01039a6:	89 c2                	mov    %eax,%edx
f01039a8:	89 d0                	mov    %edx,%eax
f01039aa:	01 c0                	add    %eax,%eax
f01039ac:	01 d0                	add    %edx,%eax
f01039ae:	c1 e0 02             	shl    $0x2,%eax
f01039b1:	89 c2                	mov    %eax,%edx
f01039b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01039b6:	01 d0                	add    %edx,%eax
f01039b8:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f01039bc:	3c a0                	cmp    $0xa0,%al
f01039be:	75 0f                	jne    f01039cf <debuginfo_eip+0x34b>
			(info->eip_fn_narg)++;
f01039c0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039c3:	8b 40 14             	mov    0x14(%eax),%eax
f01039c6:	8d 50 01             	lea    0x1(%eax),%edx
f01039c9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039cc:	89 50 14             	mov    %edx,0x14(%eax)
		lfun++;
f01039cf:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01039d2:	83 c0 01             	add    $0x1,%eax
f01039d5:	89 45 dc             	mov    %eax,-0x24(%ebp)

	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	// Your code here.
	info->eip_fn_narg=0;
	while (lfun<=rfun)
f01039d8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01039db:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01039de:	39 c2                	cmp    %eax,%edx
f01039e0:	7e c1                	jle    f01039a3 <debuginfo_eip+0x31f>
	{
		if (stabs[lfun].n_type== N_PSYM)
			(info->eip_fn_narg)++;
		lfun++;
	}	
	return 0;
f01039e2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01039e7:	c9                   	leave  
f01039e8:	c3                   	ret    

f01039e9 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01039e9:	55                   	push   %ebp
f01039ea:	89 e5                	mov    %esp,%ebp
f01039ec:	53                   	push   %ebx
f01039ed:	83 ec 34             	sub    $0x34,%esp
f01039f0:	8b 45 10             	mov    0x10(%ebp),%eax
f01039f3:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01039f6:	8b 45 14             	mov    0x14(%ebp),%eax
f01039f9:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01039fc:	8b 45 18             	mov    0x18(%ebp),%eax
f01039ff:	ba 00 00 00 00       	mov    $0x0,%edx
f0103a04:	3b 55 f4             	cmp    -0xc(%ebp),%edx
f0103a07:	77 72                	ja     f0103a7b <printnum+0x92>
f0103a09:	3b 55 f4             	cmp    -0xc(%ebp),%edx
f0103a0c:	72 05                	jb     f0103a13 <printnum+0x2a>
f0103a0e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
f0103a11:	77 68                	ja     f0103a7b <printnum+0x92>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103a13:	8b 45 1c             	mov    0x1c(%ebp),%eax
f0103a16:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103a19:	8b 45 18             	mov    0x18(%ebp),%eax
f0103a1c:	ba 00 00 00 00       	mov    $0x0,%edx
f0103a21:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103a25:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103a29:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103a2c:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103a2f:	89 04 24             	mov    %eax,(%esp)
f0103a32:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103a36:	e8 15 0c 00 00       	call   f0104650 <__udivdi3>
f0103a3b:	8b 4d 20             	mov    0x20(%ebp),%ecx
f0103a3e:	89 4c 24 18          	mov    %ecx,0x18(%esp)
f0103a42:	89 5c 24 14          	mov    %ebx,0x14(%esp)
f0103a46:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0103a49:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103a4d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103a51:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103a55:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a58:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a5c:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a5f:	89 04 24             	mov    %eax,(%esp)
f0103a62:	e8 82 ff ff ff       	call   f01039e9 <printnum>
f0103a67:	eb 1c                	jmp    f0103a85 <printnum+0x9c>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103a69:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a6c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a70:	8b 45 20             	mov    0x20(%ebp),%eax
f0103a73:	89 04 24             	mov    %eax,(%esp)
f0103a76:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a79:	ff d0                	call   *%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103a7b:	83 6d 1c 01          	subl   $0x1,0x1c(%ebp)
f0103a7f:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
f0103a83:	7f e4                	jg     f0103a69 <printnum+0x80>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103a85:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0103a88:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103a8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103a90:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103a93:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103a97:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103a9b:	89 04 24             	mov    %eax,(%esp)
f0103a9e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103aa2:	e8 d9 0c 00 00       	call   f0104780 <__umoddi3>
f0103aa7:	05 a0 53 10 f0       	add    $0xf01053a0,%eax
f0103aac:	0f b6 00             	movzbl (%eax),%eax
f0103aaf:	0f be c0             	movsbl %al,%eax
f0103ab2:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103ab5:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103ab9:	89 04 24             	mov    %eax,(%esp)
f0103abc:	8b 45 08             	mov    0x8(%ebp),%eax
f0103abf:	ff d0                	call   *%eax
}
f0103ac1:	83 c4 34             	add    $0x34,%esp
f0103ac4:	5b                   	pop    %ebx
f0103ac5:	5d                   	pop    %ebp
f0103ac6:	c3                   	ret    

f0103ac7 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103ac7:	55                   	push   %ebp
f0103ac8:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103aca:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f0103ace:	7e 1c                	jle    f0103aec <getuint+0x25>
		return va_arg(*ap, unsigned long long);
f0103ad0:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ad3:	8b 00                	mov    (%eax),%eax
f0103ad5:	8d 50 08             	lea    0x8(%eax),%edx
f0103ad8:	8b 45 08             	mov    0x8(%ebp),%eax
f0103adb:	89 10                	mov    %edx,(%eax)
f0103add:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ae0:	8b 00                	mov    (%eax),%eax
f0103ae2:	83 e8 08             	sub    $0x8,%eax
f0103ae5:	8b 50 04             	mov    0x4(%eax),%edx
f0103ae8:	8b 00                	mov    (%eax),%eax
f0103aea:	eb 40                	jmp    f0103b2c <getuint+0x65>
	else if (lflag)
f0103aec:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103af0:	74 1e                	je     f0103b10 <getuint+0x49>
		return va_arg(*ap, unsigned long);
f0103af2:	8b 45 08             	mov    0x8(%ebp),%eax
f0103af5:	8b 00                	mov    (%eax),%eax
f0103af7:	8d 50 04             	lea    0x4(%eax),%edx
f0103afa:	8b 45 08             	mov    0x8(%ebp),%eax
f0103afd:	89 10                	mov    %edx,(%eax)
f0103aff:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b02:	8b 00                	mov    (%eax),%eax
f0103b04:	83 e8 04             	sub    $0x4,%eax
f0103b07:	8b 00                	mov    (%eax),%eax
f0103b09:	ba 00 00 00 00       	mov    $0x0,%edx
f0103b0e:	eb 1c                	jmp    f0103b2c <getuint+0x65>
	else
		return va_arg(*ap, unsigned int);
f0103b10:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b13:	8b 00                	mov    (%eax),%eax
f0103b15:	8d 50 04             	lea    0x4(%eax),%edx
f0103b18:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b1b:	89 10                	mov    %edx,(%eax)
f0103b1d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b20:	8b 00                	mov    (%eax),%eax
f0103b22:	83 e8 04             	sub    $0x4,%eax
f0103b25:	8b 00                	mov    (%eax),%eax
f0103b27:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103b2c:	5d                   	pop    %ebp
f0103b2d:	c3                   	ret    

f0103b2e <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0103b2e:	55                   	push   %ebp
f0103b2f:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103b31:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f0103b35:	7e 1c                	jle    f0103b53 <getint+0x25>
		return va_arg(*ap, long long);
f0103b37:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b3a:	8b 00                	mov    (%eax),%eax
f0103b3c:	8d 50 08             	lea    0x8(%eax),%edx
f0103b3f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b42:	89 10                	mov    %edx,(%eax)
f0103b44:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b47:	8b 00                	mov    (%eax),%eax
f0103b49:	83 e8 08             	sub    $0x8,%eax
f0103b4c:	8b 50 04             	mov    0x4(%eax),%edx
f0103b4f:	8b 00                	mov    (%eax),%eax
f0103b51:	eb 38                	jmp    f0103b8b <getint+0x5d>
	else if (lflag)
f0103b53:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103b57:	74 1a                	je     f0103b73 <getint+0x45>
		return va_arg(*ap, long);
f0103b59:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b5c:	8b 00                	mov    (%eax),%eax
f0103b5e:	8d 50 04             	lea    0x4(%eax),%edx
f0103b61:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b64:	89 10                	mov    %edx,(%eax)
f0103b66:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b69:	8b 00                	mov    (%eax),%eax
f0103b6b:	83 e8 04             	sub    $0x4,%eax
f0103b6e:	8b 00                	mov    (%eax),%eax
f0103b70:	99                   	cltd   
f0103b71:	eb 18                	jmp    f0103b8b <getint+0x5d>
	else
		return va_arg(*ap, int);
f0103b73:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b76:	8b 00                	mov    (%eax),%eax
f0103b78:	8d 50 04             	lea    0x4(%eax),%edx
f0103b7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b7e:	89 10                	mov    %edx,(%eax)
f0103b80:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b83:	8b 00                	mov    (%eax),%eax
f0103b85:	83 e8 04             	sub    $0x4,%eax
f0103b88:	8b 00                	mov    (%eax),%eax
f0103b8a:	99                   	cltd   
}
f0103b8b:	5d                   	pop    %ebp
f0103b8c:	c3                   	ret    

f0103b8d <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103b8d:	55                   	push   %ebp
f0103b8e:	89 e5                	mov    %esp,%ebp
f0103b90:	56                   	push   %esi
f0103b91:	53                   	push   %ebx
f0103b92:	83 ec 40             	sub    $0x40,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103b95:	eb 18                	jmp    f0103baf <vprintfmt+0x22>
			if (ch == '\0')
f0103b97:	85 db                	test   %ebx,%ebx
f0103b99:	75 05                	jne    f0103ba0 <vprintfmt+0x13>
				return;
f0103b9b:	e9 ea 03 00 00       	jmp    f0103f8a <vprintfmt+0x3fd>
			putch(ch, putdat);
f0103ba0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103ba3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ba7:	89 1c 24             	mov    %ebx,(%esp)
f0103baa:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bad:	ff d0                	call   *%eax
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103baf:	8b 45 10             	mov    0x10(%ebp),%eax
f0103bb2:	8d 50 01             	lea    0x1(%eax),%edx
f0103bb5:	89 55 10             	mov    %edx,0x10(%ebp)
f0103bb8:	0f b6 00             	movzbl (%eax),%eax
f0103bbb:	0f b6 d8             	movzbl %al,%ebx
f0103bbe:	83 fb 25             	cmp    $0x25,%ebx
f0103bc1:	75 d4                	jne    f0103b97 <vprintfmt+0xa>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		padc = ' ';
f0103bc3:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
		width = -1;
f0103bc7:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
		precision = -1;
f0103bce:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0103bd5:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
		altflag = 0;
f0103bdc:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103be3:	8b 45 10             	mov    0x10(%ebp),%eax
f0103be6:	8d 50 01             	lea    0x1(%eax),%edx
f0103be9:	89 55 10             	mov    %edx,0x10(%ebp)
f0103bec:	0f b6 00             	movzbl (%eax),%eax
f0103bef:	0f b6 d8             	movzbl %al,%ebx
f0103bf2:	8d 43 dd             	lea    -0x23(%ebx),%eax
f0103bf5:	83 f8 55             	cmp    $0x55,%eax
f0103bf8:	0f 87 5b 03 00 00    	ja     f0103f59 <vprintfmt+0x3cc>
f0103bfe:	8b 04 85 c4 53 10 f0 	mov    -0xfefac3c(,%eax,4),%eax
f0103c05:	ff e0                	jmp    *%eax

		// flag to pad on the right
		case '-':
			padc = '-';
f0103c07:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
			goto reswitch;
f0103c0b:	eb d6                	jmp    f0103be3 <vprintfmt+0x56>
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103c0d:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
			goto reswitch;
f0103c11:	eb d0                	jmp    f0103be3 <vprintfmt+0x56>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103c13:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
				precision = precision * 10 + ch - '0';
f0103c1a:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103c1d:	89 d0                	mov    %edx,%eax
f0103c1f:	c1 e0 02             	shl    $0x2,%eax
f0103c22:	01 d0                	add    %edx,%eax
f0103c24:	01 c0                	add    %eax,%eax
f0103c26:	01 d8                	add    %ebx,%eax
f0103c28:	83 e8 30             	sub    $0x30,%eax
f0103c2b:	89 45 e0             	mov    %eax,-0x20(%ebp)
				ch = *fmt;
f0103c2e:	8b 45 10             	mov    0x10(%ebp),%eax
f0103c31:	0f b6 00             	movzbl (%eax),%eax
f0103c34:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
f0103c37:	83 fb 2f             	cmp    $0x2f,%ebx
f0103c3a:	7e 0b                	jle    f0103c47 <vprintfmt+0xba>
f0103c3c:	83 fb 39             	cmp    $0x39,%ebx
f0103c3f:	7f 06                	jg     f0103c47 <vprintfmt+0xba>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103c41:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103c45:	eb d3                	jmp    f0103c1a <vprintfmt+0x8d>
			goto process_precision;
f0103c47:	eb 39                	jmp    f0103c82 <vprintfmt+0xf5>

		case '*':
			precision = va_arg(ap, int);
f0103c49:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c4c:	83 c0 04             	add    $0x4,%eax
f0103c4f:	89 45 14             	mov    %eax,0x14(%ebp)
f0103c52:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c55:	83 e8 04             	sub    $0x4,%eax
f0103c58:	8b 00                	mov    (%eax),%eax
f0103c5a:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto process_precision;
f0103c5d:	eb 23                	jmp    f0103c82 <vprintfmt+0xf5>

		case '.':
			if (width < 0)
f0103c5f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103c63:	79 0c                	jns    f0103c71 <vprintfmt+0xe4>
				width = 0;
f0103c65:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			goto reswitch;
f0103c6c:	e9 72 ff ff ff       	jmp    f0103be3 <vprintfmt+0x56>
f0103c71:	e9 6d ff ff ff       	jmp    f0103be3 <vprintfmt+0x56>

		case '#':
			altflag = 1;
f0103c76:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0103c7d:	e9 61 ff ff ff       	jmp    f0103be3 <vprintfmt+0x56>

		process_precision:
			if (width < 0)
f0103c82:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103c86:	79 12                	jns    f0103c9a <vprintfmt+0x10d>
				width = precision, precision = -1;
f0103c88:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103c8b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103c8e:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
			goto reswitch;
f0103c95:	e9 49 ff ff ff       	jmp    f0103be3 <vprintfmt+0x56>
f0103c9a:	e9 44 ff ff ff       	jmp    f0103be3 <vprintfmt+0x56>

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103c9f:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
			goto reswitch;
f0103ca3:	e9 3b ff ff ff       	jmp    f0103be3 <vprintfmt+0x56>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103ca8:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cab:	83 c0 04             	add    $0x4,%eax
f0103cae:	89 45 14             	mov    %eax,0x14(%ebp)
f0103cb1:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cb4:	83 e8 04             	sub    $0x4,%eax
f0103cb7:	8b 00                	mov    (%eax),%eax
f0103cb9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103cbc:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103cc0:	89 04 24             	mov    %eax,(%esp)
f0103cc3:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cc6:	ff d0                	call   *%eax
			break;
f0103cc8:	e9 b7 02 00 00       	jmp    f0103f84 <vprintfmt+0x3f7>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103ccd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cd0:	83 c0 04             	add    $0x4,%eax
f0103cd3:	89 45 14             	mov    %eax,0x14(%ebp)
f0103cd6:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cd9:	83 e8 04             	sub    $0x4,%eax
f0103cdc:	8b 18                	mov    (%eax),%ebx
			if (err < 0)
f0103cde:	85 db                	test   %ebx,%ebx
f0103ce0:	79 02                	jns    f0103ce4 <vprintfmt+0x157>
				err = -err;
f0103ce2:	f7 db                	neg    %ebx
			if (err > MAXERROR || (p = error_string[err]) == NULL)
f0103ce4:	83 fb 06             	cmp    $0x6,%ebx
f0103ce7:	7f 0b                	jg     f0103cf4 <vprintfmt+0x167>
f0103ce9:	8b 34 9d 84 53 10 f0 	mov    -0xfefac7c(,%ebx,4),%esi
f0103cf0:	85 f6                	test   %esi,%esi
f0103cf2:	75 23                	jne    f0103d17 <vprintfmt+0x18a>
				printfmt(putch, putdat, "error %d", err);
f0103cf4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103cf8:	c7 44 24 08 b1 53 10 	movl   $0xf01053b1,0x8(%esp)
f0103cff:	f0 
f0103d00:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103d03:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d07:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d0a:	89 04 24             	mov    %eax,(%esp)
f0103d0d:	e8 7f 02 00 00       	call   f0103f91 <printfmt>
			else
				printfmt(putch, putdat, "%s", p);
			break;
f0103d12:	e9 6d 02 00 00       	jmp    f0103f84 <vprintfmt+0x3f7>
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f0103d17:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103d1b:	c7 44 24 08 ba 53 10 	movl   $0xf01053ba,0x8(%esp)
f0103d22:	f0 
f0103d23:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103d26:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d2a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d2d:	89 04 24             	mov    %eax,(%esp)
f0103d30:	e8 5c 02 00 00       	call   f0103f91 <printfmt>
			break;
f0103d35:	e9 4a 02 00 00       	jmp    f0103f84 <vprintfmt+0x3f7>

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103d3a:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d3d:	83 c0 04             	add    $0x4,%eax
f0103d40:	89 45 14             	mov    %eax,0x14(%ebp)
f0103d43:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d46:	83 e8 04             	sub    $0x4,%eax
f0103d49:	8b 30                	mov    (%eax),%esi
f0103d4b:	85 f6                	test   %esi,%esi
f0103d4d:	75 05                	jne    f0103d54 <vprintfmt+0x1c7>
				p = "(null)";
f0103d4f:	be bd 53 10 f0       	mov    $0xf01053bd,%esi
			if (width > 0 && padc != '-')
f0103d54:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103d58:	7e 37                	jle    f0103d91 <vprintfmt+0x204>
f0103d5a:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
f0103d5e:	74 31                	je     f0103d91 <vprintfmt+0x204>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103d60:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103d63:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d67:	89 34 24             	mov    %esi,(%esp)
f0103d6a:	e8 32 04 00 00       	call   f01041a1 <strnlen>
f0103d6f:	29 45 e4             	sub    %eax,-0x1c(%ebp)
f0103d72:	eb 17                	jmp    f0103d8b <vprintfmt+0x1fe>
					putch(padc, putdat);
f0103d74:	0f be 45 db          	movsbl -0x25(%ebp),%eax
f0103d78:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103d7b:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103d7f:	89 04 24             	mov    %eax,(%esp)
f0103d82:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d85:	ff d0                	call   *%eax
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103d87:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f0103d8b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103d8f:	7f e3                	jg     f0103d74 <vprintfmt+0x1e7>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103d91:	eb 38                	jmp    f0103dcb <vprintfmt+0x23e>
				if (altflag && (ch < ' ' || ch > '~'))
f0103d93:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103d97:	74 1f                	je     f0103db8 <vprintfmt+0x22b>
f0103d99:	83 fb 1f             	cmp    $0x1f,%ebx
f0103d9c:	7e 05                	jle    f0103da3 <vprintfmt+0x216>
f0103d9e:	83 fb 7e             	cmp    $0x7e,%ebx
f0103da1:	7e 15                	jle    f0103db8 <vprintfmt+0x22b>
					putch('?', putdat);
f0103da3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103da6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103daa:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103db1:	8b 45 08             	mov    0x8(%ebp),%eax
f0103db4:	ff d0                	call   *%eax
f0103db6:	eb 0f                	jmp    f0103dc7 <vprintfmt+0x23a>
				else
					putch(ch, putdat);
f0103db8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103dbb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103dbf:	89 1c 24             	mov    %ebx,(%esp)
f0103dc2:	8b 45 08             	mov    0x8(%ebp),%eax
f0103dc5:	ff d0                	call   *%eax
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103dc7:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f0103dcb:	89 f0                	mov    %esi,%eax
f0103dcd:	8d 70 01             	lea    0x1(%eax),%esi
f0103dd0:	0f b6 00             	movzbl (%eax),%eax
f0103dd3:	0f be d8             	movsbl %al,%ebx
f0103dd6:	85 db                	test   %ebx,%ebx
f0103dd8:	74 10                	je     f0103dea <vprintfmt+0x25d>
f0103dda:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103dde:	78 b3                	js     f0103d93 <vprintfmt+0x206>
f0103de0:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0103de4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103de8:	79 a9                	jns    f0103d93 <vprintfmt+0x206>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103dea:	eb 17                	jmp    f0103e03 <vprintfmt+0x276>
				putch(' ', putdat);
f0103dec:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103def:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103df3:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103dfa:	8b 45 08             	mov    0x8(%ebp),%eax
f0103dfd:	ff d0                	call   *%eax
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103dff:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f0103e03:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103e07:	7f e3                	jg     f0103dec <vprintfmt+0x25f>
				putch(' ', putdat);
			break;
f0103e09:	e9 76 01 00 00       	jmp    f0103f84 <vprintfmt+0x3f7>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103e0e:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103e11:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e15:	8d 45 14             	lea    0x14(%ebp),%eax
f0103e18:	89 04 24             	mov    %eax,(%esp)
f0103e1b:	e8 0e fd ff ff       	call   f0103b2e <getint>
f0103e20:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103e23:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((long long) num < 0) {
f0103e26:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103e29:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103e2c:	85 d2                	test   %edx,%edx
f0103e2e:	79 26                	jns    f0103e56 <vprintfmt+0x2c9>
				putch('-', putdat);
f0103e30:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103e33:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e37:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103e3e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e41:	ff d0                	call   *%eax
				num = -(long long) num;
f0103e43:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103e46:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103e49:	f7 d8                	neg    %eax
f0103e4b:	83 d2 00             	adc    $0x0,%edx
f0103e4e:	f7 da                	neg    %edx
f0103e50:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103e53:	89 55 f4             	mov    %edx,-0xc(%ebp)
			}
			base = 10;
f0103e56:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
f0103e5d:	e9 ae 00 00 00       	jmp    f0103f10 <vprintfmt+0x383>

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103e62:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103e65:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e69:	8d 45 14             	lea    0x14(%ebp),%eax
f0103e6c:	89 04 24             	mov    %eax,(%esp)
f0103e6f:	e8 53 fc ff ff       	call   f0103ac7 <getuint>
f0103e74:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103e77:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 10;
f0103e7a:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
f0103e81:	e9 8a 00 00 00       	jmp    f0103f10 <vprintfmt+0x383>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0103e86:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103e89:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e8d:	8d 45 14             	lea    0x14(%ebp),%eax
f0103e90:	89 04 24             	mov    %eax,(%esp)
f0103e93:	e8 2f fc ff ff       	call   f0103ac7 <getuint>
f0103e98:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103e9b:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 8;
f0103e9e:	c7 45 ec 08 00 00 00 	movl   $0x8,-0x14(%ebp)
			goto number;
f0103ea5:	eb 69                	jmp    f0103f10 <vprintfmt+0x383>

		// pointer
		case 'p':
			putch('0', putdat);
f0103ea7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103eaa:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103eae:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0103eb5:	8b 45 08             	mov    0x8(%ebp),%eax
f0103eb8:	ff d0                	call   *%eax
			putch('x', putdat);
f0103eba:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103ebd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ec1:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0103ec8:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ecb:	ff d0                	call   *%eax
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103ecd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ed0:	83 c0 04             	add    $0x4,%eax
f0103ed3:	89 45 14             	mov    %eax,0x14(%ebp)
f0103ed6:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ed9:	83 e8 04             	sub    $0x4,%eax
f0103edc:	8b 00                	mov    (%eax),%eax

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103ede:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103ee1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103ee8:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
			goto number;
f0103eef:	eb 1f                	jmp    f0103f10 <vprintfmt+0x383>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103ef1:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103ef4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ef8:	8d 45 14             	lea    0x14(%ebp),%eax
f0103efb:	89 04 24             	mov    %eax,(%esp)
f0103efe:	e8 c4 fb ff ff       	call   f0103ac7 <getuint>
f0103f03:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103f06:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 16;
f0103f09:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103f10:	0f be 55 db          	movsbl -0x25(%ebp),%edx
f0103f14:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103f17:	89 54 24 18          	mov    %edx,0x18(%esp)
f0103f1b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103f1e:	89 54 24 14          	mov    %edx,0x14(%esp)
f0103f22:	89 44 24 10          	mov    %eax,0x10(%esp)
f0103f26:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103f29:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103f2c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f30:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103f34:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f37:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f3b:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f3e:	89 04 24             	mov    %eax,(%esp)
f0103f41:	e8 a3 fa ff ff       	call   f01039e9 <printnum>
			break;
f0103f46:	eb 3c                	jmp    f0103f84 <vprintfmt+0x3f7>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103f48:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f4b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f4f:	89 1c 24             	mov    %ebx,(%esp)
f0103f52:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f55:	ff d0                	call   *%eax
			break;
f0103f57:	eb 2b                	jmp    f0103f84 <vprintfmt+0x3f7>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103f59:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f5c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f60:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103f67:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f6a:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103f6c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f0103f70:	eb 04                	jmp    f0103f76 <vprintfmt+0x3e9>
f0103f72:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f0103f76:	8b 45 10             	mov    0x10(%ebp),%eax
f0103f79:	83 e8 01             	sub    $0x1,%eax
f0103f7c:	0f b6 00             	movzbl (%eax),%eax
f0103f7f:	3c 25                	cmp    $0x25,%al
f0103f81:	75 ef                	jne    f0103f72 <vprintfmt+0x3e5>
				/* do nothing */;
			break;
f0103f83:	90                   	nop
		}
	}
f0103f84:	90                   	nop
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103f85:	e9 25 fc ff ff       	jmp    f0103baf <vprintfmt+0x22>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
f0103f8a:	83 c4 40             	add    $0x40,%esp
f0103f8d:	5b                   	pop    %ebx
f0103f8e:	5e                   	pop    %esi
f0103f8f:	5d                   	pop    %ebp
f0103f90:	c3                   	ret    

f0103f91 <printfmt>:

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103f91:	55                   	push   %ebp
f0103f92:	89 e5                	mov    %esp,%ebp
f0103f94:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
f0103f97:	8d 45 10             	lea    0x10(%ebp),%eax
f0103f9a:	83 c0 04             	add    $0x4,%eax
f0103f9d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	vprintfmt(putch, putdat, fmt, ap);
f0103fa0:	8b 45 10             	mov    0x10(%ebp),%eax
f0103fa3:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103fa6:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103faa:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103fae:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103fb1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103fb5:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fb8:	89 04 24             	mov    %eax,(%esp)
f0103fbb:	e8 cd fb ff ff       	call   f0103b8d <vprintfmt>
	va_end(ap);
}
f0103fc0:	c9                   	leave  
f0103fc1:	c3                   	ret    

f0103fc2 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103fc2:	55                   	push   %ebp
f0103fc3:	89 e5                	mov    %esp,%ebp
	b->cnt++;
f0103fc5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103fc8:	8b 40 08             	mov    0x8(%eax),%eax
f0103fcb:	8d 50 01             	lea    0x1(%eax),%edx
f0103fce:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103fd1:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
f0103fd4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103fd7:	8b 10                	mov    (%eax),%edx
f0103fd9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103fdc:	8b 40 04             	mov    0x4(%eax),%eax
f0103fdf:	39 c2                	cmp    %eax,%edx
f0103fe1:	73 12                	jae    f0103ff5 <sprintputch+0x33>
		*b->buf++ = ch;
f0103fe3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103fe6:	8b 00                	mov    (%eax),%eax
f0103fe8:	8d 48 01             	lea    0x1(%eax),%ecx
f0103feb:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103fee:	89 0a                	mov    %ecx,(%edx)
f0103ff0:	8b 55 08             	mov    0x8(%ebp),%edx
f0103ff3:	88 10                	mov    %dl,(%eax)
}
f0103ff5:	5d                   	pop    %ebp
f0103ff6:	c3                   	ret    

f0103ff7 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103ff7:	55                   	push   %ebp
f0103ff8:	89 e5                	mov    %esp,%ebp
f0103ffa:	83 ec 28             	sub    $0x28,%esp
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103ffd:	8b 45 08             	mov    0x8(%ebp),%eax
f0104000:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104003:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104006:	8d 50 ff             	lea    -0x1(%eax),%edx
f0104009:	8b 45 08             	mov    0x8(%ebp),%eax
f010400c:	01 d0                	add    %edx,%eax
f010400e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104011:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104018:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010401c:	74 06                	je     f0104024 <vsnprintf+0x2d>
f010401e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104022:	7f 07                	jg     f010402b <vsnprintf+0x34>
		return -E_INVAL;
f0104024:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104029:	eb 2a                	jmp    f0104055 <vsnprintf+0x5e>

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010402b:	8b 45 14             	mov    0x14(%ebp),%eax
f010402e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104032:	8b 45 10             	mov    0x10(%ebp),%eax
f0104035:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104039:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010403c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104040:	c7 04 24 c2 3f 10 f0 	movl   $0xf0103fc2,(%esp)
f0104047:	e8 41 fb ff ff       	call   f0103b8d <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010404c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010404f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104052:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0104055:	c9                   	leave  
f0104056:	c3                   	ret    

f0104057 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104057:	55                   	push   %ebp
f0104058:	89 e5                	mov    %esp,%ebp
f010405a:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010405d:	8d 45 10             	lea    0x10(%ebp),%eax
f0104060:	83 c0 04             	add    $0x4,%eax
f0104063:	89 45 f4             	mov    %eax,-0xc(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
f0104066:	8b 45 10             	mov    0x10(%ebp),%eax
f0104069:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010406c:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104070:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104074:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104077:	89 44 24 04          	mov    %eax,0x4(%esp)
f010407b:	8b 45 08             	mov    0x8(%ebp),%eax
f010407e:	89 04 24             	mov    %eax,(%esp)
f0104081:	e8 71 ff ff ff       	call   f0103ff7 <vsnprintf>
f0104086:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return rc;
f0104089:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
f010408c:	c9                   	leave  
f010408d:	c3                   	ret    

f010408e <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010408e:	55                   	push   %ebp
f010408f:	89 e5                	mov    %esp,%ebp
f0104091:	83 ec 28             	sub    $0x28,%esp
	int i, c, echoing;

	if (prompt != NULL)
f0104094:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0104098:	74 13                	je     f01040ad <readline+0x1f>
		cprintf("%s", prompt);
f010409a:	8b 45 08             	mov    0x8(%ebp),%eax
f010409d:	89 44 24 04          	mov    %eax,0x4(%esp)
f01040a1:	c7 04 24 1c 55 10 f0 	movl   $0xf010551c,(%esp)
f01040a8:	e8 5b f4 ff ff       	call   f0103508 <cprintf>

	i = 0;
f01040ad:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	echoing = iscons(0);
f01040b4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01040bb:	e8 1c c8 ff ff       	call   f01008dc <iscons>
f01040c0:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while (1) {
		c = getchar();
f01040c3:	e8 fb c7 ff ff       	call   f01008c3 <getchar>
f01040c8:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (c < 0) {
f01040cb:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01040cf:	79 1d                	jns    f01040ee <readline+0x60>
			cprintf("read error: %e\n", c);
f01040d1:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01040d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01040d8:	c7 04 24 1f 55 10 f0 	movl   $0xf010551f,(%esp)
f01040df:	e8 24 f4 ff ff       	call   f0103508 <cprintf>
			return NULL;
f01040e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01040e9:	e9 8b 00 00 00       	jmp    f0104179 <readline+0xeb>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01040ee:	83 7d ec 1f          	cmpl   $0x1f,-0x14(%ebp)
f01040f2:	7e 2e                	jle    f0104122 <readline+0x94>
f01040f4:	81 7d f4 fe 03 00 00 	cmpl   $0x3fe,-0xc(%ebp)
f01040fb:	7f 25                	jg     f0104122 <readline+0x94>
			if (echoing)
f01040fd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0104101:	74 0b                	je     f010410e <readline+0x80>
				cputchar(c);
f0104103:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104106:	89 04 24             	mov    %eax,(%esp)
f0104109:	e8 a2 c7 ff ff       	call   f01008b0 <cputchar>
			buf[i++] = c;
f010410e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104111:	8d 50 01             	lea    0x1(%eax),%edx
f0104114:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0104117:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010411a:	88 90 20 78 11 f0    	mov    %dl,-0xfee87e0(%eax)
f0104120:	eb 52                	jmp    f0104174 <readline+0xe6>
		} else if (c == '\b' && i > 0) {
f0104122:	83 7d ec 08          	cmpl   $0x8,-0x14(%ebp)
f0104126:	75 1d                	jne    f0104145 <readline+0xb7>
f0104128:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f010412c:	7e 17                	jle    f0104145 <readline+0xb7>
			if (echoing)
f010412e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0104132:	74 0b                	je     f010413f <readline+0xb1>
				cputchar(c);
f0104134:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104137:	89 04 24             	mov    %eax,(%esp)
f010413a:	e8 71 c7 ff ff       	call   f01008b0 <cputchar>
			i--;
f010413f:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
f0104143:	eb 2f                	jmp    f0104174 <readline+0xe6>
		} else if (c == '\n' || c == '\r') {
f0104145:	83 7d ec 0a          	cmpl   $0xa,-0x14(%ebp)
f0104149:	74 06                	je     f0104151 <readline+0xc3>
f010414b:	83 7d ec 0d          	cmpl   $0xd,-0x14(%ebp)
f010414f:	75 23                	jne    f0104174 <readline+0xe6>
			if (echoing)
f0104151:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0104155:	74 0b                	je     f0104162 <readline+0xd4>
				cputchar(c);
f0104157:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010415a:	89 04 24             	mov    %eax,(%esp)
f010415d:	e8 4e c7 ff ff       	call   f01008b0 <cputchar>
			buf[i] = 0;
f0104162:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104165:	05 20 78 11 f0       	add    $0xf0117820,%eax
f010416a:	c6 00 00             	movb   $0x0,(%eax)
			return buf;
f010416d:	b8 20 78 11 f0       	mov    $0xf0117820,%eax
f0104172:	eb 05                	jmp    f0104179 <readline+0xeb>
		}
	}
f0104174:	e9 4a ff ff ff       	jmp    f01040c3 <readline+0x35>
}
f0104179:	c9                   	leave  
f010417a:	c3                   	ret    

f010417b <strlen>:

#include <inc/string.h>

int
strlen(const char *s)
{
f010417b:	55                   	push   %ebp
f010417c:	89 e5                	mov    %esp,%ebp
f010417e:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
f0104181:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0104188:	eb 08                	jmp    f0104192 <strlen+0x17>
		n++;
f010418a:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010418e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0104192:	8b 45 08             	mov    0x8(%ebp),%eax
f0104195:	0f b6 00             	movzbl (%eax),%eax
f0104198:	84 c0                	test   %al,%al
f010419a:	75 ee                	jne    f010418a <strlen+0xf>
		n++;
	return n;
f010419c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f010419f:	c9                   	leave  
f01041a0:	c3                   	ret    

f01041a1 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01041a1:	55                   	push   %ebp
f01041a2:	89 e5                	mov    %esp,%ebp
f01041a4:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01041a7:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f01041ae:	eb 0c                	jmp    f01041bc <strnlen+0x1b>
		n++;
f01041b0:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01041b4:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f01041b8:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
f01041bc:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01041c0:	74 0a                	je     f01041cc <strnlen+0x2b>
f01041c2:	8b 45 08             	mov    0x8(%ebp),%eax
f01041c5:	0f b6 00             	movzbl (%eax),%eax
f01041c8:	84 c0                	test   %al,%al
f01041ca:	75 e4                	jne    f01041b0 <strnlen+0xf>
		n++;
	return n;
f01041cc:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f01041cf:	c9                   	leave  
f01041d0:	c3                   	ret    

f01041d1 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01041d1:	55                   	push   %ebp
f01041d2:	89 e5                	mov    %esp,%ebp
f01041d4:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
f01041d7:	8b 45 08             	mov    0x8(%ebp),%eax
f01041da:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
f01041dd:	90                   	nop
f01041de:	8b 45 08             	mov    0x8(%ebp),%eax
f01041e1:	8d 50 01             	lea    0x1(%eax),%edx
f01041e4:	89 55 08             	mov    %edx,0x8(%ebp)
f01041e7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01041ea:	8d 4a 01             	lea    0x1(%edx),%ecx
f01041ed:	89 4d 0c             	mov    %ecx,0xc(%ebp)
f01041f0:	0f b6 12             	movzbl (%edx),%edx
f01041f3:	88 10                	mov    %dl,(%eax)
f01041f5:	0f b6 00             	movzbl (%eax),%eax
f01041f8:	84 c0                	test   %al,%al
f01041fa:	75 e2                	jne    f01041de <strcpy+0xd>
		/* do nothing */;
	return ret;
f01041fc:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f01041ff:	c9                   	leave  
f0104200:	c3                   	ret    

f0104201 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104201:	55                   	push   %ebp
f0104202:	89 e5                	mov    %esp,%ebp
f0104204:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
f0104207:	8b 45 08             	mov    0x8(%ebp),%eax
f010420a:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
f010420d:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0104214:	eb 23                	jmp    f0104239 <strncpy+0x38>
		*dst++ = *src;
f0104216:	8b 45 08             	mov    0x8(%ebp),%eax
f0104219:	8d 50 01             	lea    0x1(%eax),%edx
f010421c:	89 55 08             	mov    %edx,0x8(%ebp)
f010421f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104222:	0f b6 12             	movzbl (%edx),%edx
f0104225:	88 10                	mov    %dl,(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
f0104227:	8b 45 0c             	mov    0xc(%ebp),%eax
f010422a:	0f b6 00             	movzbl (%eax),%eax
f010422d:	84 c0                	test   %al,%al
f010422f:	74 04                	je     f0104235 <strncpy+0x34>
			src++;
f0104231:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104235:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f0104239:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010423c:	3b 45 10             	cmp    0x10(%ebp),%eax
f010423f:	72 d5                	jb     f0104216 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
f0104241:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f0104244:	c9                   	leave  
f0104245:	c3                   	ret    

f0104246 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104246:	55                   	push   %ebp
f0104247:	89 e5                	mov    %esp,%ebp
f0104249:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
f010424c:	8b 45 08             	mov    0x8(%ebp),%eax
f010424f:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
f0104252:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104256:	74 33                	je     f010428b <strlcpy+0x45>
		while (--size > 0 && *src != '\0')
f0104258:	eb 17                	jmp    f0104271 <strlcpy+0x2b>
			*dst++ = *src++;
f010425a:	8b 45 08             	mov    0x8(%ebp),%eax
f010425d:	8d 50 01             	lea    0x1(%eax),%edx
f0104260:	89 55 08             	mov    %edx,0x8(%ebp)
f0104263:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104266:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104269:	89 4d 0c             	mov    %ecx,0xc(%ebp)
f010426c:	0f b6 12             	movzbl (%edx),%edx
f010426f:	88 10                	mov    %dl,(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104271:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f0104275:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104279:	74 0a                	je     f0104285 <strlcpy+0x3f>
f010427b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010427e:	0f b6 00             	movzbl (%eax),%eax
f0104281:	84 c0                	test   %al,%al
f0104283:	75 d5                	jne    f010425a <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
f0104285:	8b 45 08             	mov    0x8(%ebp),%eax
f0104288:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010428b:	8b 55 08             	mov    0x8(%ebp),%edx
f010428e:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104291:	29 c2                	sub    %eax,%edx
f0104293:	89 d0                	mov    %edx,%eax
}
f0104295:	c9                   	leave  
f0104296:	c3                   	ret    

f0104297 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104297:	55                   	push   %ebp
f0104298:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
f010429a:	eb 08                	jmp    f01042a4 <strcmp+0xd>
		p++, q++;
f010429c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f01042a0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01042a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01042a7:	0f b6 00             	movzbl (%eax),%eax
f01042aa:	84 c0                	test   %al,%al
f01042ac:	74 10                	je     f01042be <strcmp+0x27>
f01042ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01042b1:	0f b6 10             	movzbl (%eax),%edx
f01042b4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01042b7:	0f b6 00             	movzbl (%eax),%eax
f01042ba:	38 c2                	cmp    %al,%dl
f01042bc:	74 de                	je     f010429c <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01042be:	8b 45 08             	mov    0x8(%ebp),%eax
f01042c1:	0f b6 00             	movzbl (%eax),%eax
f01042c4:	0f b6 d0             	movzbl %al,%edx
f01042c7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01042ca:	0f b6 00             	movzbl (%eax),%eax
f01042cd:	0f b6 c0             	movzbl %al,%eax
f01042d0:	29 c2                	sub    %eax,%edx
f01042d2:	89 d0                	mov    %edx,%eax
}
f01042d4:	5d                   	pop    %ebp
f01042d5:	c3                   	ret    

f01042d6 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01042d6:	55                   	push   %ebp
f01042d7:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
f01042d9:	eb 0c                	jmp    f01042e7 <strncmp+0x11>
		n--, p++, q++;
f01042db:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f01042df:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f01042e3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01042e7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01042eb:	74 1a                	je     f0104307 <strncmp+0x31>
f01042ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01042f0:	0f b6 00             	movzbl (%eax),%eax
f01042f3:	84 c0                	test   %al,%al
f01042f5:	74 10                	je     f0104307 <strncmp+0x31>
f01042f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01042fa:	0f b6 10             	movzbl (%eax),%edx
f01042fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104300:	0f b6 00             	movzbl (%eax),%eax
f0104303:	38 c2                	cmp    %al,%dl
f0104305:	74 d4                	je     f01042db <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
f0104307:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010430b:	75 07                	jne    f0104314 <strncmp+0x3e>
		return 0;
f010430d:	b8 00 00 00 00       	mov    $0x0,%eax
f0104312:	eb 16                	jmp    f010432a <strncmp+0x54>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104314:	8b 45 08             	mov    0x8(%ebp),%eax
f0104317:	0f b6 00             	movzbl (%eax),%eax
f010431a:	0f b6 d0             	movzbl %al,%edx
f010431d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104320:	0f b6 00             	movzbl (%eax),%eax
f0104323:	0f b6 c0             	movzbl %al,%eax
f0104326:	29 c2                	sub    %eax,%edx
f0104328:	89 d0                	mov    %edx,%eax
}
f010432a:	5d                   	pop    %ebp
f010432b:	c3                   	ret    

f010432c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010432c:	55                   	push   %ebp
f010432d:	89 e5                	mov    %esp,%ebp
f010432f:	83 ec 04             	sub    $0x4,%esp
f0104332:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104335:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
f0104338:	eb 14                	jmp    f010434e <strchr+0x22>
		if (*s == c)
f010433a:	8b 45 08             	mov    0x8(%ebp),%eax
f010433d:	0f b6 00             	movzbl (%eax),%eax
f0104340:	3a 45 fc             	cmp    -0x4(%ebp),%al
f0104343:	75 05                	jne    f010434a <strchr+0x1e>
			return (char *) s;
f0104345:	8b 45 08             	mov    0x8(%ebp),%eax
f0104348:	eb 13                	jmp    f010435d <strchr+0x31>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010434a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f010434e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104351:	0f b6 00             	movzbl (%eax),%eax
f0104354:	84 c0                	test   %al,%al
f0104356:	75 e2                	jne    f010433a <strchr+0xe>
		if (*s == c)
			return (char *) s;
	return 0;
f0104358:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010435d:	c9                   	leave  
f010435e:	c3                   	ret    

f010435f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010435f:	55                   	push   %ebp
f0104360:	89 e5                	mov    %esp,%ebp
f0104362:	83 ec 04             	sub    $0x4,%esp
f0104365:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104368:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
f010436b:	eb 11                	jmp    f010437e <strfind+0x1f>
		if (*s == c)
f010436d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104370:	0f b6 00             	movzbl (%eax),%eax
f0104373:	3a 45 fc             	cmp    -0x4(%ebp),%al
f0104376:	75 02                	jne    f010437a <strfind+0x1b>
			break;
f0104378:	eb 0e                	jmp    f0104388 <strfind+0x29>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010437a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f010437e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104381:	0f b6 00             	movzbl (%eax),%eax
f0104384:	84 c0                	test   %al,%al
f0104386:	75 e5                	jne    f010436d <strfind+0xe>
		if (*s == c)
			break;
	return (char *) s;
f0104388:	8b 45 08             	mov    0x8(%ebp),%eax
}
f010438b:	c9                   	leave  
f010438c:	c3                   	ret    

f010438d <memset>:


void *
memset(void *v, int c, size_t n)
{
f010438d:	55                   	push   %ebp
f010438e:	89 e5                	mov    %esp,%ebp
f0104390:	83 ec 10             	sub    $0x10,%esp
	char *p;
	int m;

	p = v;
f0104393:	8b 45 08             	mov    0x8(%ebp),%eax
f0104396:	89 45 fc             	mov    %eax,-0x4(%ebp)
	m = n;
f0104399:	8b 45 10             	mov    0x10(%ebp),%eax
f010439c:	89 45 f8             	mov    %eax,-0x8(%ebp)
	while (--m >= 0)
f010439f:	eb 0e                	jmp    f01043af <memset+0x22>
		*p++ = c;
f01043a1:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01043a4:	8d 50 01             	lea    0x1(%eax),%edx
f01043a7:	89 55 fc             	mov    %edx,-0x4(%ebp)
f01043aa:	8b 55 0c             	mov    0xc(%ebp),%edx
f01043ad:	88 10                	mov    %dl,(%eax)
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f01043af:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
f01043b3:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
f01043b7:	79 e8                	jns    f01043a1 <memset+0x14>
		*p++ = c;

	return v;
f01043b9:	8b 45 08             	mov    0x8(%ebp),%eax
}
f01043bc:	c9                   	leave  
f01043bd:	c3                   	ret    

f01043be <memmove>:

/* no memcpy - use memmove instead */

void *
memmove(void *dst, const void *src, size_t n)
{
f01043be:	55                   	push   %ebp
f01043bf:	89 e5                	mov    %esp,%ebp
f01043c1:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
f01043c4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043c7:	89 45 fc             	mov    %eax,-0x4(%ebp)
	d = dst;
f01043ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01043cd:	89 45 f8             	mov    %eax,-0x8(%ebp)
	if (s < d && s + n > d) {
f01043d0:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01043d3:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f01043d6:	73 3d                	jae    f0104415 <memmove+0x57>
f01043d8:	8b 45 10             	mov    0x10(%ebp),%eax
f01043db:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01043de:	01 d0                	add    %edx,%eax
f01043e0:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f01043e3:	76 30                	jbe    f0104415 <memmove+0x57>
		s += n;
f01043e5:	8b 45 10             	mov    0x10(%ebp),%eax
f01043e8:	01 45 fc             	add    %eax,-0x4(%ebp)
		d += n;
f01043eb:	8b 45 10             	mov    0x10(%ebp),%eax
f01043ee:	01 45 f8             	add    %eax,-0x8(%ebp)
		while (n-- > 0)
f01043f1:	eb 13                	jmp    f0104406 <memmove+0x48>
			*--d = *--s;
f01043f3:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
f01043f7:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
f01043fb:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01043fe:	0f b6 10             	movzbl (%eax),%edx
f0104401:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0104404:	88 10                	mov    %dl,(%eax)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
f0104406:	8b 45 10             	mov    0x10(%ebp),%eax
f0104409:	8d 50 ff             	lea    -0x1(%eax),%edx
f010440c:	89 55 10             	mov    %edx,0x10(%ebp)
f010440f:	85 c0                	test   %eax,%eax
f0104411:	75 e0                	jne    f01043f3 <memmove+0x35>
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104413:	eb 26                	jmp    f010443b <memmove+0x7d>
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f0104415:	eb 17                	jmp    f010442e <memmove+0x70>
			*d++ = *s++;
f0104417:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010441a:	8d 50 01             	lea    0x1(%eax),%edx
f010441d:	89 55 f8             	mov    %edx,-0x8(%ebp)
f0104420:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0104423:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104426:	89 4d fc             	mov    %ecx,-0x4(%ebp)
f0104429:	0f b6 12             	movzbl (%edx),%edx
f010442c:	88 10                	mov    %dl,(%eax)
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f010442e:	8b 45 10             	mov    0x10(%ebp),%eax
f0104431:	8d 50 ff             	lea    -0x1(%eax),%edx
f0104434:	89 55 10             	mov    %edx,0x10(%ebp)
f0104437:	85 c0                	test   %eax,%eax
f0104439:	75 dc                	jne    f0104417 <memmove+0x59>
			*d++ = *s++;

	return dst;
f010443b:	8b 45 08             	mov    0x8(%ebp),%eax
}
f010443e:	c9                   	leave  
f010443f:	c3                   	ret    

f0104440 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0104440:	55                   	push   %ebp
f0104441:	89 e5                	mov    %esp,%ebp
f0104443:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0104446:	8b 45 10             	mov    0x10(%ebp),%eax
f0104449:	89 44 24 08          	mov    %eax,0x8(%esp)
f010444d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104450:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104454:	8b 45 08             	mov    0x8(%ebp),%eax
f0104457:	89 04 24             	mov    %eax,(%esp)
f010445a:	e8 5f ff ff ff       	call   f01043be <memmove>
}
f010445f:	c9                   	leave  
f0104460:	c3                   	ret    

f0104461 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104461:	55                   	push   %ebp
f0104462:	89 e5                	mov    %esp,%ebp
f0104464:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
f0104467:	8b 45 08             	mov    0x8(%ebp),%eax
f010446a:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
f010446d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104470:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
f0104473:	eb 30                	jmp    f01044a5 <memcmp+0x44>
		if (*s1 != *s2)
f0104475:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104478:	0f b6 10             	movzbl (%eax),%edx
f010447b:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010447e:	0f b6 00             	movzbl (%eax),%eax
f0104481:	38 c2                	cmp    %al,%dl
f0104483:	74 18                	je     f010449d <memcmp+0x3c>
			return (int) *s1 - (int) *s2;
f0104485:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104488:	0f b6 00             	movzbl (%eax),%eax
f010448b:	0f b6 d0             	movzbl %al,%edx
f010448e:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0104491:	0f b6 00             	movzbl (%eax),%eax
f0104494:	0f b6 c0             	movzbl %al,%eax
f0104497:	29 c2                	sub    %eax,%edx
f0104499:	89 d0                	mov    %edx,%eax
f010449b:	eb 1a                	jmp    f01044b7 <memcmp+0x56>
		s1++, s2++;
f010449d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f01044a1:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01044a5:	8b 45 10             	mov    0x10(%ebp),%eax
f01044a8:	8d 50 ff             	lea    -0x1(%eax),%edx
f01044ab:	89 55 10             	mov    %edx,0x10(%ebp)
f01044ae:	85 c0                	test   %eax,%eax
f01044b0:	75 c3                	jne    f0104475 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01044b2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01044b7:	c9                   	leave  
f01044b8:	c3                   	ret    

f01044b9 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01044b9:	55                   	push   %ebp
f01044ba:	89 e5                	mov    %esp,%ebp
f01044bc:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
f01044bf:	8b 45 10             	mov    0x10(%ebp),%eax
f01044c2:	8b 55 08             	mov    0x8(%ebp),%edx
f01044c5:	01 d0                	add    %edx,%eax
f01044c7:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
f01044ca:	eb 13                	jmp    f01044df <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f01044cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01044cf:	0f b6 10             	movzbl (%eax),%edx
f01044d2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01044d5:	38 c2                	cmp    %al,%dl
f01044d7:	75 02                	jne    f01044db <memfind+0x22>
			break;
f01044d9:	eb 0c                	jmp    f01044e7 <memfind+0x2e>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01044db:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f01044df:	8b 45 08             	mov    0x8(%ebp),%eax
f01044e2:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f01044e5:	72 e5                	jb     f01044cc <memfind+0x13>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
f01044e7:	8b 45 08             	mov    0x8(%ebp),%eax
}
f01044ea:	c9                   	leave  
f01044eb:	c3                   	ret    

f01044ec <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01044ec:	55                   	push   %ebp
f01044ed:	89 e5                	mov    %esp,%ebp
f01044ef:	83 ec 10             	sub    $0x10,%esp
	int neg = 0;
f01044f2:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	long val = 0;
f01044f9:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104500:	eb 04                	jmp    f0104506 <strtol+0x1a>
		s++;
f0104502:	83 45 08 01          	addl   $0x1,0x8(%ebp)
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104506:	8b 45 08             	mov    0x8(%ebp),%eax
f0104509:	0f b6 00             	movzbl (%eax),%eax
f010450c:	3c 20                	cmp    $0x20,%al
f010450e:	74 f2                	je     f0104502 <strtol+0x16>
f0104510:	8b 45 08             	mov    0x8(%ebp),%eax
f0104513:	0f b6 00             	movzbl (%eax),%eax
f0104516:	3c 09                	cmp    $0x9,%al
f0104518:	74 e8                	je     f0104502 <strtol+0x16>
		s++;

	// plus/minus sign
	if (*s == '+')
f010451a:	8b 45 08             	mov    0x8(%ebp),%eax
f010451d:	0f b6 00             	movzbl (%eax),%eax
f0104520:	3c 2b                	cmp    $0x2b,%al
f0104522:	75 06                	jne    f010452a <strtol+0x3e>
		s++;
f0104524:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0104528:	eb 15                	jmp    f010453f <strtol+0x53>
	else if (*s == '-')
f010452a:	8b 45 08             	mov    0x8(%ebp),%eax
f010452d:	0f b6 00             	movzbl (%eax),%eax
f0104530:	3c 2d                	cmp    $0x2d,%al
f0104532:	75 0b                	jne    f010453f <strtol+0x53>
		s++, neg = 1;
f0104534:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0104538:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010453f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104543:	74 06                	je     f010454b <strtol+0x5f>
f0104545:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
f0104549:	75 24                	jne    f010456f <strtol+0x83>
f010454b:	8b 45 08             	mov    0x8(%ebp),%eax
f010454e:	0f b6 00             	movzbl (%eax),%eax
f0104551:	3c 30                	cmp    $0x30,%al
f0104553:	75 1a                	jne    f010456f <strtol+0x83>
f0104555:	8b 45 08             	mov    0x8(%ebp),%eax
f0104558:	83 c0 01             	add    $0x1,%eax
f010455b:	0f b6 00             	movzbl (%eax),%eax
f010455e:	3c 78                	cmp    $0x78,%al
f0104560:	75 0d                	jne    f010456f <strtol+0x83>
		s += 2, base = 16;
f0104562:	83 45 08 02          	addl   $0x2,0x8(%ebp)
f0104566:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
f010456d:	eb 2a                	jmp    f0104599 <strtol+0xad>
	else if (base == 0 && s[0] == '0')
f010456f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104573:	75 17                	jne    f010458c <strtol+0xa0>
f0104575:	8b 45 08             	mov    0x8(%ebp),%eax
f0104578:	0f b6 00             	movzbl (%eax),%eax
f010457b:	3c 30                	cmp    $0x30,%al
f010457d:	75 0d                	jne    f010458c <strtol+0xa0>
		s++, base = 8;
f010457f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0104583:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
f010458a:	eb 0d                	jmp    f0104599 <strtol+0xad>
	else if (base == 0)
f010458c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104590:	75 07                	jne    f0104599 <strtol+0xad>
		base = 10;
f0104592:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104599:	8b 45 08             	mov    0x8(%ebp),%eax
f010459c:	0f b6 00             	movzbl (%eax),%eax
f010459f:	3c 2f                	cmp    $0x2f,%al
f01045a1:	7e 1b                	jle    f01045be <strtol+0xd2>
f01045a3:	8b 45 08             	mov    0x8(%ebp),%eax
f01045a6:	0f b6 00             	movzbl (%eax),%eax
f01045a9:	3c 39                	cmp    $0x39,%al
f01045ab:	7f 11                	jg     f01045be <strtol+0xd2>
			dig = *s - '0';
f01045ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01045b0:	0f b6 00             	movzbl (%eax),%eax
f01045b3:	0f be c0             	movsbl %al,%eax
f01045b6:	83 e8 30             	sub    $0x30,%eax
f01045b9:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01045bc:	eb 48                	jmp    f0104606 <strtol+0x11a>
		else if (*s >= 'a' && *s <= 'z')
f01045be:	8b 45 08             	mov    0x8(%ebp),%eax
f01045c1:	0f b6 00             	movzbl (%eax),%eax
f01045c4:	3c 60                	cmp    $0x60,%al
f01045c6:	7e 1b                	jle    f01045e3 <strtol+0xf7>
f01045c8:	8b 45 08             	mov    0x8(%ebp),%eax
f01045cb:	0f b6 00             	movzbl (%eax),%eax
f01045ce:	3c 7a                	cmp    $0x7a,%al
f01045d0:	7f 11                	jg     f01045e3 <strtol+0xf7>
			dig = *s - 'a' + 10;
f01045d2:	8b 45 08             	mov    0x8(%ebp),%eax
f01045d5:	0f b6 00             	movzbl (%eax),%eax
f01045d8:	0f be c0             	movsbl %al,%eax
f01045db:	83 e8 57             	sub    $0x57,%eax
f01045de:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01045e1:	eb 23                	jmp    f0104606 <strtol+0x11a>
		else if (*s >= 'A' && *s <= 'Z')
f01045e3:	8b 45 08             	mov    0x8(%ebp),%eax
f01045e6:	0f b6 00             	movzbl (%eax),%eax
f01045e9:	3c 40                	cmp    $0x40,%al
f01045eb:	7e 3d                	jle    f010462a <strtol+0x13e>
f01045ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01045f0:	0f b6 00             	movzbl (%eax),%eax
f01045f3:	3c 5a                	cmp    $0x5a,%al
f01045f5:	7f 33                	jg     f010462a <strtol+0x13e>
			dig = *s - 'A' + 10;
f01045f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01045fa:	0f b6 00             	movzbl (%eax),%eax
f01045fd:	0f be c0             	movsbl %al,%eax
f0104600:	83 e8 37             	sub    $0x37,%eax
f0104603:	89 45 f4             	mov    %eax,-0xc(%ebp)
		else
			break;
		if (dig >= base)
f0104606:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104609:	3b 45 10             	cmp    0x10(%ebp),%eax
f010460c:	7c 02                	jl     f0104610 <strtol+0x124>
			break;
f010460e:	eb 1a                	jmp    f010462a <strtol+0x13e>
		s++, val = (val * base) + dig;
f0104610:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0104614:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0104617:	0f af 45 10          	imul   0x10(%ebp),%eax
f010461b:	89 c2                	mov    %eax,%edx
f010461d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104620:	01 d0                	add    %edx,%eax
f0104622:	89 45 f8             	mov    %eax,-0x8(%ebp)
		// we don't properly detect overflow!
	}
f0104625:	e9 6f ff ff ff       	jmp    f0104599 <strtol+0xad>

	if (endptr)
f010462a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010462e:	74 08                	je     f0104638 <strtol+0x14c>
		*endptr = (char *) s;
f0104630:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104633:	8b 55 08             	mov    0x8(%ebp),%edx
f0104636:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
f0104638:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f010463c:	74 07                	je     f0104645 <strtol+0x159>
f010463e:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0104641:	f7 d8                	neg    %eax
f0104643:	eb 03                	jmp    f0104648 <strtol+0x15c>
f0104645:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f0104648:	c9                   	leave  
f0104649:	c3                   	ret    
f010464a:	66 90                	xchg   %ax,%ax
f010464c:	66 90                	xchg   %ax,%ax
f010464e:	66 90                	xchg   %ax,%ax

f0104650 <__udivdi3>:
f0104650:	55                   	push   %ebp
f0104651:	57                   	push   %edi
f0104652:	56                   	push   %esi
f0104653:	83 ec 0c             	sub    $0xc,%esp
f0104656:	8b 44 24 28          	mov    0x28(%esp),%eax
f010465a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010465e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0104662:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0104666:	85 c0                	test   %eax,%eax
f0104668:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010466c:	89 ea                	mov    %ebp,%edx
f010466e:	89 0c 24             	mov    %ecx,(%esp)
f0104671:	75 2d                	jne    f01046a0 <__udivdi3+0x50>
f0104673:	39 e9                	cmp    %ebp,%ecx
f0104675:	77 61                	ja     f01046d8 <__udivdi3+0x88>
f0104677:	85 c9                	test   %ecx,%ecx
f0104679:	89 ce                	mov    %ecx,%esi
f010467b:	75 0b                	jne    f0104688 <__udivdi3+0x38>
f010467d:	b8 01 00 00 00       	mov    $0x1,%eax
f0104682:	31 d2                	xor    %edx,%edx
f0104684:	f7 f1                	div    %ecx
f0104686:	89 c6                	mov    %eax,%esi
f0104688:	31 d2                	xor    %edx,%edx
f010468a:	89 e8                	mov    %ebp,%eax
f010468c:	f7 f6                	div    %esi
f010468e:	89 c5                	mov    %eax,%ebp
f0104690:	89 f8                	mov    %edi,%eax
f0104692:	f7 f6                	div    %esi
f0104694:	89 ea                	mov    %ebp,%edx
f0104696:	83 c4 0c             	add    $0xc,%esp
f0104699:	5e                   	pop    %esi
f010469a:	5f                   	pop    %edi
f010469b:	5d                   	pop    %ebp
f010469c:	c3                   	ret    
f010469d:	8d 76 00             	lea    0x0(%esi),%esi
f01046a0:	39 e8                	cmp    %ebp,%eax
f01046a2:	77 24                	ja     f01046c8 <__udivdi3+0x78>
f01046a4:	0f bd e8             	bsr    %eax,%ebp
f01046a7:	83 f5 1f             	xor    $0x1f,%ebp
f01046aa:	75 3c                	jne    f01046e8 <__udivdi3+0x98>
f01046ac:	8b 74 24 04          	mov    0x4(%esp),%esi
f01046b0:	39 34 24             	cmp    %esi,(%esp)
f01046b3:	0f 86 9f 00 00 00    	jbe    f0104758 <__udivdi3+0x108>
f01046b9:	39 d0                	cmp    %edx,%eax
f01046bb:	0f 82 97 00 00 00    	jb     f0104758 <__udivdi3+0x108>
f01046c1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01046c8:	31 d2                	xor    %edx,%edx
f01046ca:	31 c0                	xor    %eax,%eax
f01046cc:	83 c4 0c             	add    $0xc,%esp
f01046cf:	5e                   	pop    %esi
f01046d0:	5f                   	pop    %edi
f01046d1:	5d                   	pop    %ebp
f01046d2:	c3                   	ret    
f01046d3:	90                   	nop
f01046d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01046d8:	89 f8                	mov    %edi,%eax
f01046da:	f7 f1                	div    %ecx
f01046dc:	31 d2                	xor    %edx,%edx
f01046de:	83 c4 0c             	add    $0xc,%esp
f01046e1:	5e                   	pop    %esi
f01046e2:	5f                   	pop    %edi
f01046e3:	5d                   	pop    %ebp
f01046e4:	c3                   	ret    
f01046e5:	8d 76 00             	lea    0x0(%esi),%esi
f01046e8:	89 e9                	mov    %ebp,%ecx
f01046ea:	8b 3c 24             	mov    (%esp),%edi
f01046ed:	d3 e0                	shl    %cl,%eax
f01046ef:	89 c6                	mov    %eax,%esi
f01046f1:	b8 20 00 00 00       	mov    $0x20,%eax
f01046f6:	29 e8                	sub    %ebp,%eax
f01046f8:	89 c1                	mov    %eax,%ecx
f01046fa:	d3 ef                	shr    %cl,%edi
f01046fc:	89 e9                	mov    %ebp,%ecx
f01046fe:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104702:	8b 3c 24             	mov    (%esp),%edi
f0104705:	09 74 24 08          	or     %esi,0x8(%esp)
f0104709:	89 d6                	mov    %edx,%esi
f010470b:	d3 e7                	shl    %cl,%edi
f010470d:	89 c1                	mov    %eax,%ecx
f010470f:	89 3c 24             	mov    %edi,(%esp)
f0104712:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104716:	d3 ee                	shr    %cl,%esi
f0104718:	89 e9                	mov    %ebp,%ecx
f010471a:	d3 e2                	shl    %cl,%edx
f010471c:	89 c1                	mov    %eax,%ecx
f010471e:	d3 ef                	shr    %cl,%edi
f0104720:	09 d7                	or     %edx,%edi
f0104722:	89 f2                	mov    %esi,%edx
f0104724:	89 f8                	mov    %edi,%eax
f0104726:	f7 74 24 08          	divl   0x8(%esp)
f010472a:	89 d6                	mov    %edx,%esi
f010472c:	89 c7                	mov    %eax,%edi
f010472e:	f7 24 24             	mull   (%esp)
f0104731:	39 d6                	cmp    %edx,%esi
f0104733:	89 14 24             	mov    %edx,(%esp)
f0104736:	72 30                	jb     f0104768 <__udivdi3+0x118>
f0104738:	8b 54 24 04          	mov    0x4(%esp),%edx
f010473c:	89 e9                	mov    %ebp,%ecx
f010473e:	d3 e2                	shl    %cl,%edx
f0104740:	39 c2                	cmp    %eax,%edx
f0104742:	73 05                	jae    f0104749 <__udivdi3+0xf9>
f0104744:	3b 34 24             	cmp    (%esp),%esi
f0104747:	74 1f                	je     f0104768 <__udivdi3+0x118>
f0104749:	89 f8                	mov    %edi,%eax
f010474b:	31 d2                	xor    %edx,%edx
f010474d:	e9 7a ff ff ff       	jmp    f01046cc <__udivdi3+0x7c>
f0104752:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104758:	31 d2                	xor    %edx,%edx
f010475a:	b8 01 00 00 00       	mov    $0x1,%eax
f010475f:	e9 68 ff ff ff       	jmp    f01046cc <__udivdi3+0x7c>
f0104764:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104768:	8d 47 ff             	lea    -0x1(%edi),%eax
f010476b:	31 d2                	xor    %edx,%edx
f010476d:	83 c4 0c             	add    $0xc,%esp
f0104770:	5e                   	pop    %esi
f0104771:	5f                   	pop    %edi
f0104772:	5d                   	pop    %ebp
f0104773:	c3                   	ret    
f0104774:	66 90                	xchg   %ax,%ax
f0104776:	66 90                	xchg   %ax,%ax
f0104778:	66 90                	xchg   %ax,%ax
f010477a:	66 90                	xchg   %ax,%ax
f010477c:	66 90                	xchg   %ax,%ax
f010477e:	66 90                	xchg   %ax,%ax

f0104780 <__umoddi3>:
f0104780:	55                   	push   %ebp
f0104781:	57                   	push   %edi
f0104782:	56                   	push   %esi
f0104783:	83 ec 14             	sub    $0x14,%esp
f0104786:	8b 44 24 28          	mov    0x28(%esp),%eax
f010478a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010478e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0104792:	89 c7                	mov    %eax,%edi
f0104794:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104798:	8b 44 24 30          	mov    0x30(%esp),%eax
f010479c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01047a0:	89 34 24             	mov    %esi,(%esp)
f01047a3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01047a7:	85 c0                	test   %eax,%eax
f01047a9:	89 c2                	mov    %eax,%edx
f01047ab:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01047af:	75 17                	jne    f01047c8 <__umoddi3+0x48>
f01047b1:	39 fe                	cmp    %edi,%esi
f01047b3:	76 4b                	jbe    f0104800 <__umoddi3+0x80>
f01047b5:	89 c8                	mov    %ecx,%eax
f01047b7:	89 fa                	mov    %edi,%edx
f01047b9:	f7 f6                	div    %esi
f01047bb:	89 d0                	mov    %edx,%eax
f01047bd:	31 d2                	xor    %edx,%edx
f01047bf:	83 c4 14             	add    $0x14,%esp
f01047c2:	5e                   	pop    %esi
f01047c3:	5f                   	pop    %edi
f01047c4:	5d                   	pop    %ebp
f01047c5:	c3                   	ret    
f01047c6:	66 90                	xchg   %ax,%ax
f01047c8:	39 f8                	cmp    %edi,%eax
f01047ca:	77 54                	ja     f0104820 <__umoddi3+0xa0>
f01047cc:	0f bd e8             	bsr    %eax,%ebp
f01047cf:	83 f5 1f             	xor    $0x1f,%ebp
f01047d2:	75 5c                	jne    f0104830 <__umoddi3+0xb0>
f01047d4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01047d8:	39 3c 24             	cmp    %edi,(%esp)
f01047db:	0f 87 e7 00 00 00    	ja     f01048c8 <__umoddi3+0x148>
f01047e1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01047e5:	29 f1                	sub    %esi,%ecx
f01047e7:	19 c7                	sbb    %eax,%edi
f01047e9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01047ed:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01047f1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01047f5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01047f9:	83 c4 14             	add    $0x14,%esp
f01047fc:	5e                   	pop    %esi
f01047fd:	5f                   	pop    %edi
f01047fe:	5d                   	pop    %ebp
f01047ff:	c3                   	ret    
f0104800:	85 f6                	test   %esi,%esi
f0104802:	89 f5                	mov    %esi,%ebp
f0104804:	75 0b                	jne    f0104811 <__umoddi3+0x91>
f0104806:	b8 01 00 00 00       	mov    $0x1,%eax
f010480b:	31 d2                	xor    %edx,%edx
f010480d:	f7 f6                	div    %esi
f010480f:	89 c5                	mov    %eax,%ebp
f0104811:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104815:	31 d2                	xor    %edx,%edx
f0104817:	f7 f5                	div    %ebp
f0104819:	89 c8                	mov    %ecx,%eax
f010481b:	f7 f5                	div    %ebp
f010481d:	eb 9c                	jmp    f01047bb <__umoddi3+0x3b>
f010481f:	90                   	nop
f0104820:	89 c8                	mov    %ecx,%eax
f0104822:	89 fa                	mov    %edi,%edx
f0104824:	83 c4 14             	add    $0x14,%esp
f0104827:	5e                   	pop    %esi
f0104828:	5f                   	pop    %edi
f0104829:	5d                   	pop    %ebp
f010482a:	c3                   	ret    
f010482b:	90                   	nop
f010482c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104830:	8b 04 24             	mov    (%esp),%eax
f0104833:	be 20 00 00 00       	mov    $0x20,%esi
f0104838:	89 e9                	mov    %ebp,%ecx
f010483a:	29 ee                	sub    %ebp,%esi
f010483c:	d3 e2                	shl    %cl,%edx
f010483e:	89 f1                	mov    %esi,%ecx
f0104840:	d3 e8                	shr    %cl,%eax
f0104842:	89 e9                	mov    %ebp,%ecx
f0104844:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104848:	8b 04 24             	mov    (%esp),%eax
f010484b:	09 54 24 04          	or     %edx,0x4(%esp)
f010484f:	89 fa                	mov    %edi,%edx
f0104851:	d3 e0                	shl    %cl,%eax
f0104853:	89 f1                	mov    %esi,%ecx
f0104855:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104859:	8b 44 24 10          	mov    0x10(%esp),%eax
f010485d:	d3 ea                	shr    %cl,%edx
f010485f:	89 e9                	mov    %ebp,%ecx
f0104861:	d3 e7                	shl    %cl,%edi
f0104863:	89 f1                	mov    %esi,%ecx
f0104865:	d3 e8                	shr    %cl,%eax
f0104867:	89 e9                	mov    %ebp,%ecx
f0104869:	09 f8                	or     %edi,%eax
f010486b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010486f:	f7 74 24 04          	divl   0x4(%esp)
f0104873:	d3 e7                	shl    %cl,%edi
f0104875:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104879:	89 d7                	mov    %edx,%edi
f010487b:	f7 64 24 08          	mull   0x8(%esp)
f010487f:	39 d7                	cmp    %edx,%edi
f0104881:	89 c1                	mov    %eax,%ecx
f0104883:	89 14 24             	mov    %edx,(%esp)
f0104886:	72 2c                	jb     f01048b4 <__umoddi3+0x134>
f0104888:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010488c:	72 22                	jb     f01048b0 <__umoddi3+0x130>
f010488e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0104892:	29 c8                	sub    %ecx,%eax
f0104894:	19 d7                	sbb    %edx,%edi
f0104896:	89 e9                	mov    %ebp,%ecx
f0104898:	89 fa                	mov    %edi,%edx
f010489a:	d3 e8                	shr    %cl,%eax
f010489c:	89 f1                	mov    %esi,%ecx
f010489e:	d3 e2                	shl    %cl,%edx
f01048a0:	89 e9                	mov    %ebp,%ecx
f01048a2:	d3 ef                	shr    %cl,%edi
f01048a4:	09 d0                	or     %edx,%eax
f01048a6:	89 fa                	mov    %edi,%edx
f01048a8:	83 c4 14             	add    $0x14,%esp
f01048ab:	5e                   	pop    %esi
f01048ac:	5f                   	pop    %edi
f01048ad:	5d                   	pop    %ebp
f01048ae:	c3                   	ret    
f01048af:	90                   	nop
f01048b0:	39 d7                	cmp    %edx,%edi
f01048b2:	75 da                	jne    f010488e <__umoddi3+0x10e>
f01048b4:	8b 14 24             	mov    (%esp),%edx
f01048b7:	89 c1                	mov    %eax,%ecx
f01048b9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f01048bd:	1b 54 24 04          	sbb    0x4(%esp),%edx
f01048c1:	eb cb                	jmp    f010488e <__umoddi3+0x10e>
f01048c3:	90                   	nop
f01048c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01048c8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f01048cc:	0f 82 0f ff ff ff    	jb     f01047e1 <__umoddi3+0x61>
f01048d2:	e9 1a ff ff ff       	jmp    f01047f1 <__umoddi3+0x71>
