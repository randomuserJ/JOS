
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 40 79 11 f0       	mov    $0xf0117940,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 73 11 f0       	push   $0xf0117300
f0100058:	e8 e9 31 00 00       	call   f0103246 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 e0 36 10 f0       	push   $0xf01036e0
f010006f:	e8 19 27 00 00       	call   f010278d <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 5a 10 00 00       	call   f01010d3 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 32 07 00 00       	call   f01007b8 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 44 79 11 f0 00 	cmpl   $0x0,0xf0117944
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 44 79 11 f0    	mov    %esi,0xf0117944

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 fb 36 10 f0       	push   $0xf01036fb
f01000b5:	e8 d3 26 00 00       	call   f010278d <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 a3 26 00 00       	call   f0102767 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 f9 39 10 f0 	movl   $0xf01039f9,(%esp)
f01000cb:	e8 bd 26 00 00       	call   f010278d <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 db 06 00 00       	call   f01007b8 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 13 37 10 f0       	push   $0xf0103713
f01000f7:	e8 91 26 00 00       	call   f010278d <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 5f 26 00 00       	call   f0102767 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 f9 39 10 f0 	movl   $0xf01039f9,(%esp)
f010010f:	e8 79 26 00 00       	call   f010278d <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 75 11 f0    	mov    0xf0117524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 75 11 f0    	mov    %edx,0xf0117524
f0100159:	88 81 20 73 11 f0    	mov    %al,-0xfee8ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f8 00 00 00    	je     f0100284 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010018c:	a8 20                	test   $0x20,%al
f010018e:	0f 85 f6 00 00 00    	jne    f010028a <kbd_proc_data+0x10c>
f0100194:	ba 60 00 00 00       	mov    $0x60,%edx
f0100199:	ec                   	in     (%dx),%al
f010019a:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010019c:	3c e0                	cmp    $0xe0,%al
f010019e:	75 0d                	jne    f01001ad <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001a0:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f01001a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01001ac:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	53                   	push   %ebx
f01001b1:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001b4:	84 c0                	test   %al,%al
f01001b6:	79 36                	jns    f01001ee <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b8:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 80 38 10 f0 	movzbl -0xfefc780(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 73 11 f0       	mov    %eax,0xf0117300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 80 38 10 f0 	movzbl -0xfefc780(%edx),%eax
f0100211:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
f0100217:	0f b6 8a 80 37 10 f0 	movzbl -0xfefc880(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d 60 37 10 f0 	mov    -0xfefc8a0(,%ecx,4),%ecx
f0100231:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100235:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100238:	a8 08                	test   $0x8,%al
f010023a:	74 1b                	je     f0100257 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010023c:	89 da                	mov    %ebx,%edx
f010023e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100241:	83 f9 19             	cmp    $0x19,%ecx
f0100244:	77 05                	ja     f010024b <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f0100246:	83 eb 20             	sub    $0x20,%ebx
f0100249:	eb 0c                	jmp    f0100257 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f010024b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010024e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100251:	83 fa 19             	cmp    $0x19,%edx
f0100254:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100257:	f7 d0                	not    %eax
f0100259:	a8 06                	test   $0x6,%al
f010025b:	75 33                	jne    f0100290 <kbd_proc_data+0x112>
f010025d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100263:	75 2b                	jne    f0100290 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f0100265:	83 ec 0c             	sub    $0xc,%esp
f0100268:	68 2d 37 10 f0       	push   $0xf010372d
f010026d:	e8 1b 25 00 00       	call   f010278d <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100272:	ba 92 00 00 00       	mov    $0x92,%edx
f0100277:	b8 03 00 00 00       	mov    $0x3,%eax
f010027c:	ee                   	out    %al,(%dx)
f010027d:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100280:	89 d8                	mov    %ebx,%eax
f0100282:	eb 0e                	jmp    f0100292 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100284:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100289:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010028a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010028f:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100290:	89 d8                	mov    %ebx,%eax
}
f0100292:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100295:	c9                   	leave  
f0100296:	c3                   	ret    

f0100297 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100297:	55                   	push   %ebp
f0100298:	89 e5                	mov    %esp,%ebp
f010029a:	57                   	push   %edi
f010029b:	56                   	push   %esi
f010029c:	53                   	push   %ebx
f010029d:	83 ec 1c             	sub    $0x1c,%esp
f01002a0:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a2:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ac:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b1:	eb 09                	jmp    f01002bc <cons_putc+0x25>
f01002b3:	89 ca                	mov    %ecx,%edx
f01002b5:	ec                   	in     (%dx),%al
f01002b6:	ec                   	in     (%dx),%al
f01002b7:	ec                   	in     (%dx),%al
f01002b8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002b9:	83 c3 01             	add    $0x1,%ebx
f01002bc:	89 f2                	mov    %esi,%edx
f01002be:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002bf:	a8 20                	test   $0x20,%al
f01002c1:	75 08                	jne    f01002cb <cons_putc+0x34>
f01002c3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002c9:	7e e8                	jle    f01002b3 <cons_putc+0x1c>
f01002cb:	89 f8                	mov    %edi,%eax
f01002cd:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002d5:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002d6:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002db:	be 79 03 00 00       	mov    $0x379,%esi
f01002e0:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e5:	eb 09                	jmp    f01002f0 <cons_putc+0x59>
f01002e7:	89 ca                	mov    %ecx,%edx
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	ec                   	in     (%dx),%al
f01002ec:	ec                   	in     (%dx),%al
f01002ed:	83 c3 01             	add    $0x1,%ebx
f01002f0:	89 f2                	mov    %esi,%edx
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002f9:	7f 04                	jg     f01002ff <cons_putc+0x68>
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 e8                	jns    f01002e7 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba 78 03 00 00       	mov    $0x378,%edx
f0100304:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100308:	ee                   	out    %al,(%dx)
f0100309:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010030e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100313:	ee                   	out    %al,(%dx)
f0100314:	b8 08 00 00 00       	mov    $0x8,%eax
f0100319:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010031a:	89 fa                	mov    %edi,%edx
f010031c:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100322:	89 f8                	mov    %edi,%eax
f0100324:	80 cc 07             	or     $0x7,%ah
f0100327:	85 d2                	test   %edx,%edx
f0100329:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010032c:	89 f8                	mov    %edi,%eax
f010032e:	0f b6 c0             	movzbl %al,%eax
f0100331:	83 f8 09             	cmp    $0x9,%eax
f0100334:	74 74                	je     f01003aa <cons_putc+0x113>
f0100336:	83 f8 09             	cmp    $0x9,%eax
f0100339:	7f 0a                	jg     f0100345 <cons_putc+0xae>
f010033b:	83 f8 08             	cmp    $0x8,%eax
f010033e:	74 14                	je     f0100354 <cons_putc+0xbd>
f0100340:	e9 99 00 00 00       	jmp    f01003de <cons_putc+0x147>
f0100345:	83 f8 0a             	cmp    $0xa,%eax
f0100348:	74 3a                	je     f0100384 <cons_putc+0xed>
f010034a:	83 f8 0d             	cmp    $0xd,%eax
f010034d:	74 3d                	je     f010038c <cons_putc+0xf5>
f010034f:	e9 8a 00 00 00       	jmp    f01003de <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100354:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
f01003a8:	eb 52                	jmp    f01003fc <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003aa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003af:	e8 e3 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003b4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b9:	e8 d9 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003be:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c3:	e8 cf fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003cd:	e8 c5 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 bb fe ff ff       	call   f0100297 <cons_putc>
f01003dc:	eb 1e                	jmp    f01003fc <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003de:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 72 2e 00 00       	call   f0103293 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100427:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010042d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100433:	83 c4 10             	add    $0x10,%esp
f0100436:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010043b:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010043e:	39 d0                	cmp    %edx,%eax
f0100440:	75 f4                	jne    f0100436 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100442:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
f010045f:	8d 71 01             	lea    0x1(%ecx),%esi
f0100462:	89 d8                	mov    %ebx,%eax
f0100464:	66 c1 e8 08          	shr    $0x8,%ax
f0100468:	89 f2                	mov    %esi,%edx
f010046a:	ee                   	out    %al,(%dx)
f010046b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100470:	89 ca                	mov    %ecx,%edx
f0100472:	ee                   	out    %al,(%dx)
f0100473:	89 d8                	mov    %ebx,%eax
f0100475:	89 f2                	mov    %esi,%edx
f0100477:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100478:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047b:	5b                   	pop    %ebx
f010047c:	5e                   	pop    %esi
f010047d:	5f                   	pop    %edi
f010047e:	5d                   	pop    %ebp
f010047f:	c3                   	ret    

f0100480 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100480:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f0100487:	74 11                	je     f010049a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100489:	55                   	push   %ebp
f010048a:	89 e5                	mov    %esp,%ebp
f010048c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010048f:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100494:	e8 a2 fc ff ff       	call   f010013b <cons_intr>
}
f0100499:	c9                   	leave  
f010049a:	f3 c3                	repz ret 

f010049c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010049c:	55                   	push   %ebp
f010049d:	89 e5                	mov    %esp,%ebp
f010049f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a2:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004a7:	e8 8f fc ff ff       	call   f010013b <cons_intr>
}
f01004ac:	c9                   	leave  
f01004ad:	c3                   	ret    

f01004ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004ae:	55                   	push   %ebp
f01004af:	89 e5                	mov    %esp,%ebp
f01004b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004b4:	e8 c7 ff ff ff       	call   f0100480 <serial_intr>
	kbd_intr();
f01004b9:	e8 de ff ff ff       	call   f010049c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004be:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004c3:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004d4:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e3:	75 11                	jne    f01004f6 <cons_getc+0x48>
			cons.rpos = 0;
f01004e5:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f01004ec:	00 00 00 
f01004ef:	eb 05                	jmp    f01004f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	57                   	push   %edi
f01004fc:	56                   	push   %esi
f01004fd:	53                   	push   %ebx
f01004fe:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100501:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100508:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010050f:	5a a5 
	if (*cp != 0xA55A) {
f0100511:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100518:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051c:	74 11                	je     f010052f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010051e:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f0100525:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100528:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010052d:	eb 16                	jmp    f0100545 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010052f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100536:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f010053d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100540:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100545:	8b 3d 30 75 11 f0    	mov    0xf0117530,%edi
f010054b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100550:	89 fa                	mov    %edi,%edx
f0100552:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100553:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100556:	89 da                	mov    %ebx,%edx
f0100558:	ec                   	in     (%dx),%al
f0100559:	0f b6 c8             	movzbl %al,%ecx
f010055c:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100564:	89 fa                	mov    %edi,%edx
f0100566:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100567:	89 da                	mov    %ebx,%edx
f0100569:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056a:	89 35 2c 75 11 f0    	mov    %esi,0xf011752c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057b:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100580:	b8 00 00 00 00       	mov    $0x0,%eax
f0100585:	89 f2                	mov    %esi,%edx
f0100587:	ee                   	out    %al,(%dx)
f0100588:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010058d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100592:	ee                   	out    %al,(%dx)
f0100593:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100598:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059d:	89 da                	mov    %ebx,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005aa:	ee                   	out    %al,(%dx)
f01005ab:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b0:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c0:	ee                   	out    %al,(%dx)
f01005c1:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01005cb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cc:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d4:	3c ff                	cmp    $0xff,%al
f01005d6:	0f 95 05 34 75 11 f0 	setne  0xf0117534
f01005dd:	89 f2                	mov    %esi,%edx
f01005df:	ec                   	in     (%dx),%al
f01005e0:	89 da                	mov    %ebx,%edx
f01005e2:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e3:	80 f9 ff             	cmp    $0xff,%cl
f01005e6:	75 10                	jne    f01005f8 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005e8:	83 ec 0c             	sub    $0xc,%esp
f01005eb:	68 39 37 10 f0       	push   $0xf0103739
f01005f0:	e8 98 21 00 00       	call   f010278d <cprintf>
f01005f5:	83 c4 10             	add    $0x10,%esp
}
f01005f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005fb:	5b                   	pop    %ebx
f01005fc:	5e                   	pop    %esi
f01005fd:	5f                   	pop    %edi
f01005fe:	5d                   	pop    %ebp
f01005ff:	c3                   	ret    

f0100600 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100600:	55                   	push   %ebp
f0100601:	89 e5                	mov    %esp,%ebp
f0100603:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100606:	8b 45 08             	mov    0x8(%ebp),%eax
f0100609:	e8 89 fc ff ff       	call   f0100297 <cons_putc>
}
f010060e:	c9                   	leave  
f010060f:	c3                   	ret    

f0100610 <getchar>:

int
getchar(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100616:	e8 93 fe ff ff       	call   f01004ae <cons_getc>
f010061b:	85 c0                	test   %eax,%eax
f010061d:	74 f7                	je     f0100616 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <iscons>:

int
iscons(int fdnum)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100624:	b8 01 00 00 00       	mov    $0x1,%eax
f0100629:	5d                   	pop    %ebp
f010062a:	c3                   	ret    

f010062b <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010062b:	55                   	push   %ebp
f010062c:	89 e5                	mov    %esp,%ebp
f010062e:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100631:	68 80 39 10 f0       	push   $0xf0103980
f0100636:	68 9e 39 10 f0       	push   $0xf010399e
f010063b:	68 a3 39 10 f0       	push   $0xf01039a3
f0100640:	e8 48 21 00 00       	call   f010278d <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 38 3a 10 f0       	push   $0xf0103a38
f010064d:	68 ac 39 10 f0       	push   $0xf01039ac
f0100652:	68 a3 39 10 f0       	push   $0xf01039a3
f0100657:	e8 31 21 00 00       	call   f010278d <cprintf>
f010065c:	83 c4 0c             	add    $0xc,%esp
f010065f:	68 b5 39 10 f0       	push   $0xf01039b5
f0100664:	68 c7 39 10 f0       	push   $0xf01039c7
f0100669:	68 a3 39 10 f0       	push   $0xf01039a3
f010066e:	e8 1a 21 00 00       	call   f010278d <cprintf>
	return 0;
}
f0100673:	b8 00 00 00 00       	mov    $0x0,%eax
f0100678:	c9                   	leave  
f0100679:	c3                   	ret    

f010067a <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010067a:	55                   	push   %ebp
f010067b:	89 e5                	mov    %esp,%ebp
f010067d:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100680:	68 d1 39 10 f0       	push   $0xf01039d1
f0100685:	e8 03 21 00 00       	call   f010278d <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010068a:	83 c4 08             	add    $0x8,%esp
f010068d:	68 0c 00 10 00       	push   $0x10000c
f0100692:	68 60 3a 10 f0       	push   $0xf0103a60
f0100697:	e8 f1 20 00 00       	call   f010278d <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 0c 00 10 00       	push   $0x10000c
f01006a4:	68 0c 00 10 f0       	push   $0xf010000c
f01006a9:	68 88 3a 10 f0       	push   $0xf0103a88
f01006ae:	e8 da 20 00 00       	call   f010278d <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 d1 36 10 00       	push   $0x1036d1
f01006bb:	68 d1 36 10 f0       	push   $0xf01036d1
f01006c0:	68 ac 3a 10 f0       	push   $0xf0103aac
f01006c5:	e8 c3 20 00 00       	call   f010278d <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 00 73 11 00       	push   $0x117300
f01006d2:	68 00 73 11 f0       	push   $0xf0117300
f01006d7:	68 d0 3a 10 f0       	push   $0xf0103ad0
f01006dc:	e8 ac 20 00 00       	call   f010278d <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e1:	83 c4 0c             	add    $0xc,%esp
f01006e4:	68 40 79 11 00       	push   $0x117940
f01006e9:	68 40 79 11 f0       	push   $0xf0117940
f01006ee:	68 f4 3a 10 f0       	push   $0xf0103af4
f01006f3:	e8 95 20 00 00       	call   f010278d <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006f8:	b8 3f 7d 11 f0       	mov    $0xf0117d3f,%eax
f01006fd:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100702:	83 c4 08             	add    $0x8,%esp
f0100705:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010070a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100710:	85 c0                	test   %eax,%eax
f0100712:	0f 48 c2             	cmovs  %edx,%eax
f0100715:	c1 f8 0a             	sar    $0xa,%eax
f0100718:	50                   	push   %eax
f0100719:	68 18 3b 10 f0       	push   $0xf0103b18
f010071e:	e8 6a 20 00 00       	call   f010278d <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100723:	b8 00 00 00 00       	mov    $0x0,%eax
f0100728:	c9                   	leave  
f0100729:	c3                   	ret    

f010072a <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010072a:	55                   	push   %ebp
f010072b:	89 e5                	mov    %esp,%ebp
f010072d:	57                   	push   %edi
f010072e:	56                   	push   %esi
f010072f:	53                   	push   %ebx
f0100730:	83 ec 3c             	sub    $0x3c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100733:	89 e9                	mov    %ebp,%ecx
	struct Eipdebuginfo eip_info;

	// (inc/x86.h) Funkcia na zistenie EBP (vracia int32)
	uint32_t ebp = read_ebp();
	uint32_t* ebpp = NULL;
	uint32_t eip = (uint32_t)mon_backtrace;
f0100735:	bb 2a 07 10 f0       	mov    $0xf010072a,%ebx
		cprintf("ebp %x eip %x args %08x %08x %08x %08x %08x\n",
			ebp, eip, args[0], args[1], args[2], args[3], args[4]); 

		// debuginfo_eip vrati 0, ak bola adresa eip spravna
		// identifikuje funkciu, kde ukazuje eip a ulozi ju do eip_info
		if (debuginfo_eip(eip, &eip_info) == 0){
f010073a:	8d 7d d0             	lea    -0x30(%ebp),%edi
	uint32_t* ebpp = NULL;
	uint32_t eip = (uint32_t)mon_backtrace;
	uint32_t args[5];
	int i;

	while(ebp != 0) {
f010073d:	eb 68                	jmp    f01007a7 <mon_backtrace+0x7d>
		
		ebpp = (uint32_t*)ebp;
f010073f:	89 ce                	mov    %ecx,%esi
		
		// nacitanie argumentov	
		// premenne su v zasobniku o jedno vyssie, nez navratova adresa (+2) 
		for (i=0; i<5; i++){
f0100741:	b8 00 00 00 00       	mov    $0x0,%eax
			args[i] = *(ebpp+i+2);	
f0100746:	8b 54 81 08          	mov    0x8(%ecx,%eax,4),%edx
f010074a:	89 54 85 bc          	mov    %edx,-0x44(%ebp,%eax,4)
		
		ebpp = (uint32_t*)ebp;
		
		// nacitanie argumentov	
		// premenne su v zasobniku o jedno vyssie, nez navratova adresa (+2) 
		for (i=0; i<5; i++){
f010074e:	83 c0 01             	add    $0x1,%eax
f0100751:	83 f8 05             	cmp    $0x5,%eax
f0100754:	75 f0                	jne    f0100746 <mon_backtrace+0x1c>
			args[i] = *(ebpp+i+2);	
		}
		cprintf("ebp %x eip %x args %08x %08x %08x %08x %08x\n",
f0100756:	ff 75 cc             	pushl  -0x34(%ebp)
f0100759:	ff 75 c8             	pushl  -0x38(%ebp)
f010075c:	ff 75 c4             	pushl  -0x3c(%ebp)
f010075f:	ff 75 c0             	pushl  -0x40(%ebp)
f0100762:	ff 75 bc             	pushl  -0x44(%ebp)
f0100765:	53                   	push   %ebx
f0100766:	51                   	push   %ecx
f0100767:	68 44 3b 10 f0       	push   $0xf0103b44
f010076c:	e8 1c 20 00 00       	call   f010278d <cprintf>
			ebp, eip, args[0], args[1], args[2], args[3], args[4]); 

		// debuginfo_eip vrati 0, ak bola adresa eip spravna
		// identifikuje funkciu, kde ukazuje eip a ulozi ju do eip_info
		if (debuginfo_eip(eip, &eip_info) == 0){
f0100771:	83 c4 18             	add    $0x18,%esp
f0100774:	57                   	push   %edi
f0100775:	53                   	push   %ebx
f0100776:	e8 1c 21 00 00       	call   f0102897 <debuginfo_eip>
f010077b:	83 c4 10             	add    $0x10,%esp
f010077e:	85 c0                	test   %eax,%eax
f0100780:	75 20                	jne    f01007a2 <mon_backtrace+0x78>
			// eip_file - nazov file v ktorom je eip
			// eip_line - cislo riadku kodu
			// eip_fn_namelen - dlzka nazvu funkcie z eip (hodnota pre *)
			// eip_fn_name - nazov funkcie (dlzka vypisu prisposobena)
			// eip_fn_addr - adresa zaciatku funkcie 
			cprintf("%s:%d: %.*s+%d\n\n", eip_info.eip_file, eip_info.eip_line,
f0100782:	83 ec 08             	sub    $0x8,%esp
f0100785:	2b 5d e0             	sub    -0x20(%ebp),%ebx
f0100788:	53                   	push   %ebx
f0100789:	ff 75 d8             	pushl  -0x28(%ebp)
f010078c:	ff 75 dc             	pushl  -0x24(%ebp)
f010078f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100792:	ff 75 d0             	pushl  -0x30(%ebp)
f0100795:	68 ea 39 10 f0       	push   $0xf01039ea
f010079a:	e8 ee 1f 00 00       	call   f010278d <cprintf>
f010079f:	83 c4 20             	add    $0x20,%esp
					eip_info.eip_fn_namelen, eip_info.eip_fn_name, eip - eip_info.eip_fn_addr);
				
		}
		// eip = ebp pointer + 1 (podla obrazka stacku)
		eip = *(ebpp+1); 
f01007a2:	8b 5e 04             	mov    0x4(%esi),%ebx
		// v ebpp sa nachadza adresa predosleho ebp 
		ebp = *ebpp;	
f01007a5:	8b 0e                	mov    (%esi),%ecx
	uint32_t* ebpp = NULL;
	uint32_t eip = (uint32_t)mon_backtrace;
	uint32_t args[5];
	int i;

	while(ebp != 0) {
f01007a7:	85 c9                	test   %ecx,%ecx
f01007a9:	75 94                	jne    f010073f <mon_backtrace+0x15>
		// v ebpp sa nachadza adresa predosleho ebp 
		ebp = *ebpp;	
	}
	
	return 0;
}
f01007ab:	b8 00 00 00 00       	mov    $0x0,%eax
f01007b0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007b3:	5b                   	pop    %ebx
f01007b4:	5e                   	pop    %esi
f01007b5:	5f                   	pop    %edi
f01007b6:	5d                   	pop    %ebp
f01007b7:	c3                   	ret    

f01007b8 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007b8:	55                   	push   %ebp
f01007b9:	89 e5                	mov    %esp,%ebp
f01007bb:	57                   	push   %edi
f01007bc:	56                   	push   %esi
f01007bd:	53                   	push   %ebx
f01007be:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007c1:	68 74 3b 10 f0       	push   $0xf0103b74
f01007c6:	e8 c2 1f 00 00       	call   f010278d <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007cb:	c7 04 24 98 3b 10 f0 	movl   $0xf0103b98,(%esp)
f01007d2:	e8 b6 1f 00 00       	call   f010278d <cprintf>
f01007d7:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007da:	83 ec 0c             	sub    $0xc,%esp
f01007dd:	68 fb 39 10 f0       	push   $0xf01039fb
f01007e2:	e8 08 28 00 00       	call   f0102fef <readline>
f01007e7:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007e9:	83 c4 10             	add    $0x10,%esp
f01007ec:	85 c0                	test   %eax,%eax
f01007ee:	74 ea                	je     f01007da <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007f0:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007f7:	be 00 00 00 00       	mov    $0x0,%esi
f01007fc:	eb 0a                	jmp    f0100808 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007fe:	c6 03 00             	movb   $0x0,(%ebx)
f0100801:	89 f7                	mov    %esi,%edi
f0100803:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100806:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100808:	0f b6 03             	movzbl (%ebx),%eax
f010080b:	84 c0                	test   %al,%al
f010080d:	74 63                	je     f0100872 <monitor+0xba>
f010080f:	83 ec 08             	sub    $0x8,%esp
f0100812:	0f be c0             	movsbl %al,%eax
f0100815:	50                   	push   %eax
f0100816:	68 ff 39 10 f0       	push   $0xf01039ff
f010081b:	e8 e9 29 00 00       	call   f0103209 <strchr>
f0100820:	83 c4 10             	add    $0x10,%esp
f0100823:	85 c0                	test   %eax,%eax
f0100825:	75 d7                	jne    f01007fe <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100827:	80 3b 00             	cmpb   $0x0,(%ebx)
f010082a:	74 46                	je     f0100872 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010082c:	83 fe 0f             	cmp    $0xf,%esi
f010082f:	75 14                	jne    f0100845 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100831:	83 ec 08             	sub    $0x8,%esp
f0100834:	6a 10                	push   $0x10
f0100836:	68 04 3a 10 f0       	push   $0xf0103a04
f010083b:	e8 4d 1f 00 00       	call   f010278d <cprintf>
f0100840:	83 c4 10             	add    $0x10,%esp
f0100843:	eb 95                	jmp    f01007da <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100845:	8d 7e 01             	lea    0x1(%esi),%edi
f0100848:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010084c:	eb 03                	jmp    f0100851 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010084e:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100851:	0f b6 03             	movzbl (%ebx),%eax
f0100854:	84 c0                	test   %al,%al
f0100856:	74 ae                	je     f0100806 <monitor+0x4e>
f0100858:	83 ec 08             	sub    $0x8,%esp
f010085b:	0f be c0             	movsbl %al,%eax
f010085e:	50                   	push   %eax
f010085f:	68 ff 39 10 f0       	push   $0xf01039ff
f0100864:	e8 a0 29 00 00       	call   f0103209 <strchr>
f0100869:	83 c4 10             	add    $0x10,%esp
f010086c:	85 c0                	test   %eax,%eax
f010086e:	74 de                	je     f010084e <monitor+0x96>
f0100870:	eb 94                	jmp    f0100806 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100872:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100879:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010087a:	85 f6                	test   %esi,%esi
f010087c:	0f 84 58 ff ff ff    	je     f01007da <monitor+0x22>
f0100882:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100887:	83 ec 08             	sub    $0x8,%esp
f010088a:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010088d:	ff 34 85 c0 3b 10 f0 	pushl  -0xfefc440(,%eax,4)
f0100894:	ff 75 a8             	pushl  -0x58(%ebp)
f0100897:	e8 0f 29 00 00       	call   f01031ab <strcmp>
f010089c:	83 c4 10             	add    $0x10,%esp
f010089f:	85 c0                	test   %eax,%eax
f01008a1:	75 21                	jne    f01008c4 <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f01008a3:	83 ec 04             	sub    $0x4,%esp
f01008a6:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008a9:	ff 75 08             	pushl  0x8(%ebp)
f01008ac:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008af:	52                   	push   %edx
f01008b0:	56                   	push   %esi
f01008b1:	ff 14 85 c8 3b 10 f0 	call   *-0xfefc438(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008b8:	83 c4 10             	add    $0x10,%esp
f01008bb:	85 c0                	test   %eax,%eax
f01008bd:	78 25                	js     f01008e4 <monitor+0x12c>
f01008bf:	e9 16 ff ff ff       	jmp    f01007da <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01008c4:	83 c3 01             	add    $0x1,%ebx
f01008c7:	83 fb 03             	cmp    $0x3,%ebx
f01008ca:	75 bb                	jne    f0100887 <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008cc:	83 ec 08             	sub    $0x8,%esp
f01008cf:	ff 75 a8             	pushl  -0x58(%ebp)
f01008d2:	68 21 3a 10 f0       	push   $0xf0103a21
f01008d7:	e8 b1 1e 00 00       	call   f010278d <cprintf>
f01008dc:	83 c4 10             	add    $0x10,%esp
f01008df:	e9 f6 fe ff ff       	jmp    f01007da <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008e4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008e7:	5b                   	pop    %ebx
f01008e8:	5e                   	pop    %esi
f01008e9:	5f                   	pop    %edi
f01008ea:	5d                   	pop    %ebp
f01008eb:	c3                   	ret    

f01008ec <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01008ec:	55                   	push   %ebp
f01008ed:	89 e5                	mov    %esp,%ebp
f01008ef:	56                   	push   %esi
f01008f0:	53                   	push   %ebx
f01008f1:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01008f3:	83 ec 0c             	sub    $0xc,%esp
f01008f6:	50                   	push   %eax
f01008f7:	e8 2a 1e 00 00       	call   f0102726 <mc146818_read>
f01008fc:	89 c6                	mov    %eax,%esi
f01008fe:	83 c3 01             	add    $0x1,%ebx
f0100901:	89 1c 24             	mov    %ebx,(%esp)
f0100904:	e8 1d 1e 00 00       	call   f0102726 <mc146818_read>
f0100909:	c1 e0 08             	shl    $0x8,%eax
f010090c:	09 f0                	or     %esi,%eax
}
f010090e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100911:	5b                   	pop    %ebx
f0100912:	5e                   	pop    %esi
f0100913:	5d                   	pop    %ebp
f0100914:	c3                   	ret    

f0100915 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100915:	89 d1                	mov    %edx,%ecx
f0100917:	c1 e9 16             	shr    $0x16,%ecx
f010091a:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010091d:	a8 01                	test   $0x1,%al
f010091f:	74 52                	je     f0100973 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100921:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100926:	89 c1                	mov    %eax,%ecx
f0100928:	c1 e9 0c             	shr    $0xc,%ecx
f010092b:	3b 0d 48 79 11 f0    	cmp    0xf0117948,%ecx
f0100931:	72 1b                	jb     f010094e <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100933:	55                   	push   %ebp
f0100934:	89 e5                	mov    %esp,%ebp
f0100936:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100939:	50                   	push   %eax
f010093a:	68 e4 3b 10 f0       	push   $0xf0103be4
f010093f:	68 9e 03 00 00       	push   $0x39e
f0100944:	68 b8 43 10 f0       	push   $0xf01043b8
f0100949:	e8 3d f7 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f010094e:	c1 ea 0c             	shr    $0xc,%edx
f0100951:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100957:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010095e:	89 c2                	mov    %eax,%edx
f0100960:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100963:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100968:	85 d2                	test   %edx,%edx
f010096a:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010096f:	0f 44 c2             	cmove  %edx,%eax
f0100972:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100973:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100978:	c3                   	ret    

f0100979 <boot_alloc>:
					// + 4MB    = 0xF040 0000
						//  = 4 030 726 145 B
 	size_t MAX_PHADDR = 4*1024*1024;	//  = 0x0040 0000
						//  = 4 194 304 B1
					// od Patrika
	size_t MAX_ADDR = npages*PGSIZE;	//  = 0x 0800 0000
f0100979:	8b 0d 48 79 11 f0    	mov    0xf0117948,%ecx
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.

	if (!nextfree) {
f010097f:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f0100986:	75 11                	jne    f0100999 <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100988:	ba 3f 89 11 f0       	mov    $0xf011893f,%edx
f010098d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100993:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
// ak presiahneme povolenu pamat - zacneme panikarit ... ale kolko to je ?!
// nextfree je static, preto ostane jej hodnota ulozena pri dalsom volani funkcie

	if (n < 0) {
		panic("boot_alloc: cannot allocate negative amount of memory");
	} else if (n == 0) {
f0100999:	85 c0                	test   %eax,%eax
f010099b:	75 06                	jne    f01009a3 <boot_alloc+0x2a>
		return nextfree;
f010099d:	a1 38 75 11 f0       	mov    0xf0117538,%eax
		else
			nextfree = newfree;
	}
		
	return result;
}
f01009a2:	c3                   	ret    
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009a3:	55                   	push   %ebp
f01009a4:	89 e5                	mov    %esp,%ebp
f01009a6:	53                   	push   %ebx
f01009a7:	83 ec 04             	sub    $0x4,%esp
	if (n < 0) {
		panic("boot_alloc: cannot allocate negative amount of memory");
	} else if (n == 0) {
		return nextfree;
	} else {
		result = nextfree;
f01009aa:	8b 15 38 75 11 f0    	mov    0xf0117538,%edx

		newfree = ROUNDUP(nextfree+n, PGSIZE);
f01009b0:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f01009b7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01009bc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01009c1:	77 15                	ja     f01009d8 <boot_alloc+0x5f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01009c3:	50                   	push   %eax
f01009c4:	68 08 3c 10 f0       	push   $0xf0103c08
f01009c9:	68 9a 00 00 00       	push   $0x9a
f01009ce:	68 b8 43 10 f0       	push   $0xf01043b8
f01009d3:	e8 b3 f6 ff ff       	call   f010008b <_panic>
			
		if (PADDR(newfree) > MAX_ADDR)
f01009d8:	c1 e1 0c             	shl    $0xc,%ecx
f01009db:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f01009e1:	39 d9                	cmp    %ebx,%ecx
f01009e3:	73 17                	jae    f01009fc <boot_alloc+0x83>
			panic("boot_alloc: Out of memory");
f01009e5:	83 ec 04             	sub    $0x4,%esp
f01009e8:	68 c4 43 10 f0       	push   $0xf01043c4
f01009ed:	68 9b 00 00 00       	push   $0x9b
f01009f2:	68 b8 43 10 f0       	push   $0xf01043b8
f01009f7:	e8 8f f6 ff ff       	call   f010008b <_panic>
		else
			nextfree = newfree;
f01009fc:	a3 38 75 11 f0       	mov    %eax,0xf0117538
	}
		
	return result;
f0100a01:	89 d0                	mov    %edx,%eax
}
f0100a03:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a06:	c9                   	leave  
f0100a07:	c3                   	ret    

f0100a08 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a08:	55                   	push   %ebp
f0100a09:	89 e5                	mov    %esp,%ebp
f0100a0b:	57                   	push   %edi
f0100a0c:	56                   	push   %esi
f0100a0d:	53                   	push   %ebx
f0100a0e:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a11:	84 c0                	test   %al,%al
f0100a13:	0f 85 81 02 00 00    	jne    f0100c9a <check_page_free_list+0x292>
f0100a19:	e9 8e 02 00 00       	jmp    f0100cac <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a1e:	83 ec 04             	sub    $0x4,%esp
f0100a21:	68 2c 3c 10 f0       	push   $0xf0103c2c
f0100a26:	68 df 02 00 00       	push   $0x2df
f0100a2b:	68 b8 43 10 f0       	push   $0xf01043b8
f0100a30:	e8 56 f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a35:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a38:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a3b:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a3e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a41:	89 c2                	mov    %eax,%edx
f0100a43:	2b 15 50 79 11 f0    	sub    0xf0117950,%edx
f0100a49:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a4f:	0f 95 c2             	setne  %dl
f0100a52:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a55:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a59:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a5b:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a5f:	8b 00                	mov    (%eax),%eax
f0100a61:	85 c0                	test   %eax,%eax
f0100a63:	75 dc                	jne    f0100a41 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a65:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a68:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a6e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a71:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a74:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a76:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a79:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a7e:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a83:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100a89:	eb 53                	jmp    f0100ade <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a8b:	89 d8                	mov    %ebx,%eax
f0100a8d:	2b 05 50 79 11 f0    	sub    0xf0117950,%eax
f0100a93:	c1 f8 03             	sar    $0x3,%eax
f0100a96:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a99:	89 c2                	mov    %eax,%edx
f0100a9b:	c1 ea 16             	shr    $0x16,%edx
f0100a9e:	39 f2                	cmp    %esi,%edx
f0100aa0:	73 3a                	jae    f0100adc <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100aa2:	89 c2                	mov    %eax,%edx
f0100aa4:	c1 ea 0c             	shr    $0xc,%edx
f0100aa7:	3b 15 48 79 11 f0    	cmp    0xf0117948,%edx
f0100aad:	72 12                	jb     f0100ac1 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100aaf:	50                   	push   %eax
f0100ab0:	68 e4 3b 10 f0       	push   $0xf0103be4
f0100ab5:	6a 52                	push   $0x52
f0100ab7:	68 de 43 10 f0       	push   $0xf01043de
f0100abc:	e8 ca f5 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100ac1:	83 ec 04             	sub    $0x4,%esp
f0100ac4:	68 80 00 00 00       	push   $0x80
f0100ac9:	68 97 00 00 00       	push   $0x97
f0100ace:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ad3:	50                   	push   %eax
f0100ad4:	e8 6d 27 00 00       	call   f0103246 <memset>
f0100ad9:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100adc:	8b 1b                	mov    (%ebx),%ebx
f0100ade:	85 db                	test   %ebx,%ebx
f0100ae0:	75 a9                	jne    f0100a8b <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100ae2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ae7:	e8 8d fe ff ff       	call   f0100979 <boot_alloc>
f0100aec:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100aef:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100af5:	8b 0d 50 79 11 f0    	mov    0xf0117950,%ecx
		assert(pp < pages + npages);
f0100afb:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0100b00:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b03:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b06:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b09:	be 00 00 00 00       	mov    $0x0,%esi
f0100b0e:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b11:	e9 30 01 00 00       	jmp    f0100c46 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b16:	39 ca                	cmp    %ecx,%edx
f0100b18:	73 19                	jae    f0100b33 <check_page_free_list+0x12b>
f0100b1a:	68 ec 43 10 f0       	push   $0xf01043ec
f0100b1f:	68 f8 43 10 f0       	push   $0xf01043f8
f0100b24:	68 f9 02 00 00       	push   $0x2f9
f0100b29:	68 b8 43 10 f0       	push   $0xf01043b8
f0100b2e:	e8 58 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100b33:	39 fa                	cmp    %edi,%edx
f0100b35:	72 19                	jb     f0100b50 <check_page_free_list+0x148>
f0100b37:	68 0d 44 10 f0       	push   $0xf010440d
f0100b3c:	68 f8 43 10 f0       	push   $0xf01043f8
f0100b41:	68 fa 02 00 00       	push   $0x2fa
f0100b46:	68 b8 43 10 f0       	push   $0xf01043b8
f0100b4b:	e8 3b f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b50:	89 d0                	mov    %edx,%eax
f0100b52:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b55:	a8 07                	test   $0x7,%al
f0100b57:	74 19                	je     f0100b72 <check_page_free_list+0x16a>
f0100b59:	68 50 3c 10 f0       	push   $0xf0103c50
f0100b5e:	68 f8 43 10 f0       	push   $0xf01043f8
f0100b63:	68 fb 02 00 00       	push   $0x2fb
f0100b68:	68 b8 43 10 f0       	push   $0xf01043b8
f0100b6d:	e8 19 f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b72:	c1 f8 03             	sar    $0x3,%eax
f0100b75:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b78:	85 c0                	test   %eax,%eax
f0100b7a:	75 19                	jne    f0100b95 <check_page_free_list+0x18d>
f0100b7c:	68 21 44 10 f0       	push   $0xf0104421
f0100b81:	68 f8 43 10 f0       	push   $0xf01043f8
f0100b86:	68 fe 02 00 00       	push   $0x2fe
f0100b8b:	68 b8 43 10 f0       	push   $0xf01043b8
f0100b90:	e8 f6 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b95:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b9a:	75 19                	jne    f0100bb5 <check_page_free_list+0x1ad>
f0100b9c:	68 32 44 10 f0       	push   $0xf0104432
f0100ba1:	68 f8 43 10 f0       	push   $0xf01043f8
f0100ba6:	68 ff 02 00 00       	push   $0x2ff
f0100bab:	68 b8 43 10 f0       	push   $0xf01043b8
f0100bb0:	e8 d6 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100bb5:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100bba:	75 19                	jne    f0100bd5 <check_page_free_list+0x1cd>
f0100bbc:	68 84 3c 10 f0       	push   $0xf0103c84
f0100bc1:	68 f8 43 10 f0       	push   $0xf01043f8
f0100bc6:	68 00 03 00 00       	push   $0x300
f0100bcb:	68 b8 43 10 f0       	push   $0xf01043b8
f0100bd0:	e8 b6 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bd5:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100bda:	75 19                	jne    f0100bf5 <check_page_free_list+0x1ed>
f0100bdc:	68 4b 44 10 f0       	push   $0xf010444b
f0100be1:	68 f8 43 10 f0       	push   $0xf01043f8
f0100be6:	68 01 03 00 00       	push   $0x301
f0100beb:	68 b8 43 10 f0       	push   $0xf01043b8
f0100bf0:	e8 96 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100bf5:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100bfa:	76 3f                	jbe    f0100c3b <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bfc:	89 c3                	mov    %eax,%ebx
f0100bfe:	c1 eb 0c             	shr    $0xc,%ebx
f0100c01:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100c04:	77 12                	ja     f0100c18 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c06:	50                   	push   %eax
f0100c07:	68 e4 3b 10 f0       	push   $0xf0103be4
f0100c0c:	6a 52                	push   $0x52
f0100c0e:	68 de 43 10 f0       	push   $0xf01043de
f0100c13:	e8 73 f4 ff ff       	call   f010008b <_panic>
f0100c18:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c1d:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c20:	76 1e                	jbe    f0100c40 <check_page_free_list+0x238>
f0100c22:	68 a8 3c 10 f0       	push   $0xf0103ca8
f0100c27:	68 f8 43 10 f0       	push   $0xf01043f8
f0100c2c:	68 02 03 00 00       	push   $0x302
f0100c31:	68 b8 43 10 f0       	push   $0xf01043b8
f0100c36:	e8 50 f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c3b:	83 c6 01             	add    $0x1,%esi
f0100c3e:	eb 04                	jmp    f0100c44 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c40:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c44:	8b 12                	mov    (%edx),%edx
f0100c46:	85 d2                	test   %edx,%edx
f0100c48:	0f 85 c8 fe ff ff    	jne    f0100b16 <check_page_free_list+0x10e>
f0100c4e:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c51:	85 f6                	test   %esi,%esi
f0100c53:	7f 19                	jg     f0100c6e <check_page_free_list+0x266>
f0100c55:	68 65 44 10 f0       	push   $0xf0104465
f0100c5a:	68 f8 43 10 f0       	push   $0xf01043f8
f0100c5f:	68 0a 03 00 00       	push   $0x30a
f0100c64:	68 b8 43 10 f0       	push   $0xf01043b8
f0100c69:	e8 1d f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c6e:	85 db                	test   %ebx,%ebx
f0100c70:	7f 19                	jg     f0100c8b <check_page_free_list+0x283>
f0100c72:	68 77 44 10 f0       	push   $0xf0104477
f0100c77:	68 f8 43 10 f0       	push   $0xf01043f8
f0100c7c:	68 0b 03 00 00       	push   $0x30b
f0100c81:	68 b8 43 10 f0       	push   $0xf01043b8
f0100c86:	e8 00 f4 ff ff       	call   f010008b <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100c8b:	83 ec 0c             	sub    $0xc,%esp
f0100c8e:	68 f0 3c 10 f0       	push   $0xf0103cf0
f0100c93:	e8 f5 1a 00 00       	call   f010278d <cprintf>
}
f0100c98:	eb 29                	jmp    f0100cc3 <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c9a:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100c9f:	85 c0                	test   %eax,%eax
f0100ca1:	0f 85 8e fd ff ff    	jne    f0100a35 <check_page_free_list+0x2d>
f0100ca7:	e9 72 fd ff ff       	jmp    f0100a1e <check_page_free_list+0x16>
f0100cac:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100cb3:	0f 84 65 fd ff ff    	je     f0100a1e <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100cb9:	be 00 04 00 00       	mov    $0x400,%esi
f0100cbe:	e9 c0 fd ff ff       	jmp    f0100a83 <check_page_free_list+0x7b>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100cc3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cc6:	5b                   	pop    %ebx
f0100cc7:	5e                   	pop    %esi
f0100cc8:	5f                   	pop    %edi
f0100cc9:	5d                   	pop    %ebp
f0100cca:	c3                   	ret    

f0100ccb <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100ccb:	55                   	push   %ebp
f0100ccc:	89 e5                	mov    %esp,%ebp
f0100cce:	57                   	push   %edi
f0100ccf:	56                   	push   %esi
f0100cd0:	53                   	push   %ebx
f0100cd1:	83 ec 0c             	sub    $0xc,%esp
// IO hole <0x0A 0000 ; 0x10 0000) sa nesmnie alokovat
// smie sa alokovat az od prvej volnej stranky (preskocime celu RAMku ???)
// krenel je mapovany od KERNBASE 0xF000 0000 a ma 4MB (0xF010 0000 ???)

	size_t i;
	pages[0].pp_ref = 1;
f0100cd4:	a1 50 79 11 f0       	mov    0xf0117950,%eax
f0100cd9:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)

	for (i = 1; i < npages; i++) {
f0100cdf:	bb 00 10 00 00       	mov    $0x1000,%ebx
f0100ce4:	be 08 00 00 00       	mov    $0x8,%esi
f0100ce9:	bf 01 00 00 00       	mov    $0x1,%edi
f0100cee:	e9 8f 00 00 00       	jmp    f0100d82 <page_init+0xb7>
		if ( (i*PGSIZE >= IOPHYSMEM) && (i*PGSIZE < EXTPHYSMEM) ){
f0100cf3:	8d 83 00 00 f6 ff    	lea    -0xa0000(%ebx),%eax
f0100cf9:	3d ff ff 05 00       	cmp    $0x5ffff,%eax
f0100cfe:	77 0e                	ja     f0100d0e <page_init+0x43>
			pages[i].pp_ref = 1;
f0100d00:	a1 50 79 11 f0       	mov    0xf0117950,%eax
f0100d05:	66 c7 44 30 04 01 00 	movw   $0x1,0x4(%eax,%esi,1)
			continue;
f0100d0c:	eb 68                	jmp    f0100d76 <page_init+0xab>
		}
		if ( (i*PGSIZE >= EXTPHYSMEM) && (i*PGSIZE < PADDR(boot_alloc(0))) ){
f0100d0e:	81 fb ff ff 0f 00    	cmp    $0xfffff,%ebx
f0100d14:	76 3d                	jbe    f0100d53 <page_init+0x88>
f0100d16:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d1b:	e8 59 fc ff ff       	call   f0100979 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100d20:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100d25:	77 15                	ja     f0100d3c <page_init+0x71>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d27:	50                   	push   %eax
f0100d28:	68 08 3c 10 f0       	push   $0xf0103c08
f0100d2d:	68 5b 01 00 00       	push   $0x15b
f0100d32:	68 b8 43 10 f0       	push   $0xf01043b8
f0100d37:	e8 4f f3 ff ff       	call   f010008b <_panic>
f0100d3c:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d41:	39 d8                	cmp    %ebx,%eax
f0100d43:	76 0e                	jbe    f0100d53 <page_init+0x88>
			pages[i].pp_ref = 1;	
f0100d45:	a1 50 79 11 f0       	mov    0xf0117950,%eax
f0100d4a:	66 c7 44 30 04 01 00 	movw   $0x1,0x4(%eax,%esi,1)
			continue;
f0100d51:	eb 23                	jmp    f0100d76 <page_init+0xab>
		}

		pages[i].pp_ref = 0;
f0100d53:	89 f0                	mov    %esi,%eax
f0100d55:	03 05 50 79 11 f0    	add    0xf0117950,%eax
f0100d5b:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pages[i].pp_link = page_free_list;
f0100d61:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100d67:	89 10                	mov    %edx,(%eax)
		page_free_list = &pages[i];
f0100d69:	89 f0                	mov    %esi,%eax
f0100d6b:	03 05 50 79 11 f0    	add    0xf0117950,%eax
f0100d71:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
// krenel je mapovany od KERNBASE 0xF000 0000 a ma 4MB (0xF010 0000 ???)

	size_t i;
	pages[0].pp_ref = 1;

	for (i = 1; i < npages; i++) {
f0100d76:	83 c7 01             	add    $0x1,%edi
f0100d79:	83 c6 08             	add    $0x8,%esi
f0100d7c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100d82:	3b 3d 48 79 11 f0    	cmp    0xf0117948,%edi
f0100d88:	0f 82 65 ff ff ff    	jb     f0100cf3 <page_init+0x28>

		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	} 
}
f0100d8e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d91:	5b                   	pop    %ebx
f0100d92:	5e                   	pop    %esi
f0100d93:	5f                   	pop    %edi
f0100d94:	5d                   	pop    %ebp
f0100d95:	c3                   	ret    

f0100d96 <page_alloc>:
// smernik, ktorym ona ukazuje na dalsiu stranku a vratime jej adresu
// v komente chcu, aby sme neikrementovali pp_ref alokovanej stranky, tak nebudeme

struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d96:	55                   	push   %ebp
f0100d97:	89 e5                	mov    %esp,%ebp
f0100d99:	53                   	push   %ebx
f0100d9a:	83 ec 04             	sub    $0x4,%esp
	if (!page_free_list)
f0100d9d:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100da3:	85 db                	test   %ebx,%ebx
f0100da5:	74 58                	je     f0100dff <page_alloc+0x69>
		return NULL;

	struct PageInfo *head = NULL;

	head = page_free_list;
	page_free_list = page_free_list->pp_link;
f0100da7:	8b 03                	mov    (%ebx),%eax
f0100da9:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	head->pp_link = NULL;
f0100dae:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	if(alloc_flags & ALLOC_ZERO) 
f0100db4:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100db8:	74 45                	je     f0100dff <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100dba:	89 d8                	mov    %ebx,%eax
f0100dbc:	2b 05 50 79 11 f0    	sub    0xf0117950,%eax
f0100dc2:	c1 f8 03             	sar    $0x3,%eax
f0100dc5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dc8:	89 c2                	mov    %eax,%edx
f0100dca:	c1 ea 0c             	shr    $0xc,%edx
f0100dcd:	3b 15 48 79 11 f0    	cmp    0xf0117948,%edx
f0100dd3:	72 12                	jb     f0100de7 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dd5:	50                   	push   %eax
f0100dd6:	68 e4 3b 10 f0       	push   $0xf0103be4
f0100ddb:	6a 52                	push   $0x52
f0100ddd:	68 de 43 10 f0       	push   $0xf01043de
f0100de2:	e8 a4 f2 ff ff       	call   f010008b <_panic>
		memset(page2kva(head), '\0', PGSIZE);
f0100de7:	83 ec 04             	sub    $0x4,%esp
f0100dea:	68 00 10 00 00       	push   $0x1000
f0100def:	6a 00                	push   $0x0
f0100df1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100df6:	50                   	push   %eax
f0100df7:	e8 4a 24 00 00       	call   f0103246 <memset>
f0100dfc:	83 c4 10             	add    $0x10,%esp

	return head;
}
f0100dff:	89 d8                	mov    %ebx,%eax
f0100e01:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e04:	c9                   	leave  
f0100e05:	c3                   	ret    

f0100e06 <page_free>:
// pp->pp_link bude ukazovat na zaciatok zoznamu (page_free_list)
// zaciatok zoznamu nastavime na novu stranku pp

void
page_free(struct PageInfo *pp)
{
f0100e06:	55                   	push   %ebp
f0100e07:	89 e5                	mov    %esp,%ebp
f0100e09:	83 ec 08             	sub    $0x8,%esp
f0100e0c:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.

	if ( (pp->pp_ref != 0) || (pp->pp_link != NULL) ) 
f0100e0f:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e14:	75 05                	jne    f0100e1b <page_free+0x15>
f0100e16:	83 38 00             	cmpl   $0x0,(%eax)
f0100e19:	74 17                	je     f0100e32 <page_free+0x2c>
		panic("page_free: attempt to free page, which is in use");
f0100e1b:	83 ec 04             	sub    $0x4,%esp
f0100e1e:	68 14 3d 10 f0       	push   $0xf0103d14
f0100e23:	68 a7 01 00 00       	push   $0x1a7
f0100e28:	68 b8 43 10 f0       	push   $0xf01043b8
f0100e2d:	e8 59 f2 ff ff       	call   f010008b <_panic>

	pp->pp_link = page_free_list;
f0100e32:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100e38:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e3a:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
}
f0100e3f:	c9                   	leave  
f0100e40:	c3                   	ret    

f0100e41 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e41:	55                   	push   %ebp
f0100e42:	89 e5                	mov    %esp,%ebp
f0100e44:	83 ec 08             	sub    $0x8,%esp
f0100e47:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e4a:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e4e:	83 e8 01             	sub    $0x1,%eax
f0100e51:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e55:	66 85 c0             	test   %ax,%ax
f0100e58:	75 0c                	jne    f0100e66 <page_decref+0x25>
		page_free(pp);
f0100e5a:	83 ec 0c             	sub    $0xc,%esp
f0100e5d:	52                   	push   %edx
f0100e5e:	e8 a3 ff ff ff       	call   f0100e06 <page_free>
f0100e63:	83 c4 10             	add    $0x10,%esp
}
f0100e66:	c9                   	leave  
f0100e67:	c3                   	ret    

f0100e68 <pgdir_walk>:
// ak existuje mapovanie ... postup:
// hladame index v page dir - zoberieme prvych 10 bitov z virtualnej adresy, 
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e68:	55                   	push   %ebp
f0100e69:	89 e5                	mov    %esp,%ebp
f0100e6b:	56                   	push   %esi
f0100e6c:	53                   	push   %ebx
f0100e6d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// prvych 10 bitov va je index v tabulke pgdir
	// do hodnoty (*PD_e) pridame adresu polozky 

	pde_t *PD_entry = NULL;
	size_t PD_index = PDX(va);
	PD_entry = &pgdir[PD_index]; 
f0100e70:	89 de                	mov    %ebx,%esi
f0100e72:	c1 ee 16             	shr    $0x16,%esi
f0100e75:	c1 e6 02             	shl    $0x2,%esi
f0100e78:	03 75 08             	add    0x8(%ebp),%esi
	// tymto sme ziskali adresu polozky v pgdir
	// teraz treba vynulovat spodnych 12 bitov tejto adresy (priznakove bity)
	// pomocou makra PTA_ADDR() 
	// Z toho treba spravit virtualnu adresu, pripocitat druhych 10 bitov va

	if (*PD_entry & PTE_P)
f0100e7b:	8b 06                	mov    (%esi),%eax
f0100e7d:	a8 01                	test   $0x1,%al
f0100e7f:	74 39                	je     f0100eba <pgdir_walk+0x52>
		return (pte_t*) KADDR(PTE_ADDR(*PD_entry)) + PTX(va);
f0100e81:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e86:	89 c2                	mov    %eax,%edx
f0100e88:	c1 ea 0c             	shr    $0xc,%edx
f0100e8b:	39 15 48 79 11 f0    	cmp    %edx,0xf0117948
f0100e91:	77 15                	ja     f0100ea8 <pgdir_walk+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e93:	50                   	push   %eax
f0100e94:	68 e4 3b 10 f0       	push   $0xf0103be4
f0100e99:	68 e8 01 00 00       	push   $0x1e8
f0100e9e:	68 b8 43 10 f0       	push   $0xf01043b8
f0100ea3:	e8 e3 f1 ff ff       	call   f010008b <_panic>
f0100ea8:	c1 eb 0a             	shr    $0xa,%ebx
f0100eab:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100eb1:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f0100eb8:	eb 74                	jmp    f0100f2e <pgdir_walk+0xc6>

// preco pripocitavame PTX(va) ????? 
// dostaneme sa na adresu polozky v pg tbl ?? nieco s pointrovou aritmetikou ????

	// zaznam nie je platny (2 situacie)
	if (!create)   		// ak nechceme vytvarat mapovanie, vratime NULL
f0100eba:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100ebe:	74 62                	je     f0100f22 <pgdir_walk+0xba>
		return NULL;
				// ak chceme vytvorit mapovanie, musime alokovat
				// novu stranku 
	pp = page_alloc(ALLOC_ZERO);	// ALLOC_ZERO vynuluje stranku
f0100ec0:	83 ec 0c             	sub    $0xc,%esp
f0100ec3:	6a 01                	push   $0x1
f0100ec5:	e8 cc fe ff ff       	call   f0100d96 <page_alloc>
	if (!pp)		// ak zlyha alokacia (nemame k dispozicii volnu stranku)
f0100eca:	83 c4 10             	add    $0x10,%esp
f0100ecd:	85 c0                	test   %eax,%eax
f0100ecf:	74 58                	je     f0100f29 <pgdir_walk+0xc1>
		return NULL;

	pp->pp_ref++;		// inkrementujeme referenciu na stranku
f0100ed1:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ed6:	2b 05 50 79 11 f0    	sub    0xf0117950,%eax
f0100edc:	c1 f8 03             	sar    $0x3,%eax
f0100edf:	c1 e0 0c             	shl    $0xc,%eax

	// potrebujeme fyzicku adresu, ale mame iba pointer na strukturu PageInfo
	// nastavime priznakove bity a platnost zaznamu
	*PD_entry = page2pa(pp) | PTE_U | PTE_W | PTE_P;
f0100ee2:	89 c2                	mov    %eax,%edx
f0100ee4:	83 ca 07             	or     $0x7,%edx
f0100ee7:	89 16                	mov    %edx,(%esi)
f0100ee9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eee:	89 c2                	mov    %eax,%edx
f0100ef0:	c1 ea 0c             	shr    $0xc,%edx
f0100ef3:	3b 15 48 79 11 f0    	cmp    0xf0117948,%edx
f0100ef9:	72 15                	jb     f0100f10 <pgdir_walk+0xa8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100efb:	50                   	push   %eax
f0100efc:	68 e4 3b 10 f0       	push   $0xf0103be4
f0100f01:	68 01 02 00 00       	push   $0x201
f0100f06:	68 b8 43 10 f0       	push   $0xf01043b8
f0100f0b:	e8 7b f1 ff ff       	call   f010008b <_panic>

	// mapovanie, ktore nebolo vytvorene, sme vytvorili teraz, 
	// preto mozeme vratit opat to iste co v pripade platneho mapovania
	return (pte_t*) KADDR(PTE_ADDR(*PD_entry)) + PTX(va);
f0100f10:	c1 eb 0a             	shr    $0xa,%ebx
f0100f13:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100f19:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f0100f20:	eb 0c                	jmp    f0100f2e <pgdir_walk+0xc6>
// preco pripocitavame PTX(va) ????? 
// dostaneme sa na adresu polozky v pg tbl ?? nieco s pointrovou aritmetikou ????

	// zaznam nie je platny (2 situacie)
	if (!create)   		// ak nechceme vytvarat mapovanie, vratime NULL
		return NULL;
f0100f22:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f27:	eb 05                	jmp    f0100f2e <pgdir_walk+0xc6>
				// ak chceme vytvorit mapovanie, musime alokovat
				// novu stranku 
	pp = page_alloc(ALLOC_ZERO);	// ALLOC_ZERO vynuluje stranku
	if (!pp)		// ak zlyha alokacia (nemame k dispozicii volnu stranku)
		return NULL;
f0100f29:	b8 00 00 00 00       	mov    $0x0,%eax
	pte_t *p = KADDR(PTE_ADDR(pgdir[dindex]));


	return p+tindex;
*/
}
f0100f2e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f31:	5b                   	pop    %ebx
f0100f32:	5e                   	pop    %esi
f0100f33:	5d                   	pop    %ebp
f0100f34:	c3                   	ret    

f0100f35 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f35:	55                   	push   %ebp
f0100f36:	89 e5                	mov    %esp,%ebp
f0100f38:	57                   	push   %edi
f0100f39:	56                   	push   %esi
f0100f3a:	53                   	push   %ebx
f0100f3b:	83 ec 1c             	sub    $0x1c,%esp
f0100f3e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f41:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f44:	c1 e9 0c             	shr    $0xc,%ecx
f0100f47:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for(int i = 0; i < size/PGSIZE; i++){
f0100f4a:	89 c3                	mov    %eax,%ebx
f0100f4c:	be 00 00 00 00       	mov    $0x0,%esi
		pte_t* PT_entry = pgdir_walk(pgdir, (void*)va, 1);
f0100f51:	89 d7                	mov    %edx,%edi
f0100f53:	29 c7                	sub    %eax,%edi
		if (!PT_entry)
			panic("boot_map_region: mapping is not created");

		*PT_entry = pa | perm |PTE_P;
f0100f55:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f58:	83 c8 01             	or     $0x1,%eax
f0100f5b:	89 45 dc             	mov    %eax,-0x24(%ebp)
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	for(int i = 0; i < size/PGSIZE; i++){
f0100f5e:	eb 3f                	jmp    f0100f9f <boot_map_region+0x6a>
		pte_t* PT_entry = pgdir_walk(pgdir, (void*)va, 1);
f0100f60:	83 ec 04             	sub    $0x4,%esp
f0100f63:	6a 01                	push   $0x1
f0100f65:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0100f68:	50                   	push   %eax
f0100f69:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f6c:	e8 f7 fe ff ff       	call   f0100e68 <pgdir_walk>
		if (!PT_entry)
f0100f71:	83 c4 10             	add    $0x10,%esp
f0100f74:	85 c0                	test   %eax,%eax
f0100f76:	75 17                	jne    f0100f8f <boot_map_region+0x5a>
			panic("boot_map_region: mapping is not created");
f0100f78:	83 ec 04             	sub    $0x4,%esp
f0100f7b:	68 48 3d 10 f0       	push   $0xf0103d48
f0100f80:	68 28 02 00 00       	push   $0x228
f0100f85:	68 b8 43 10 f0       	push   $0xf01043b8
f0100f8a:	e8 fc f0 ff ff       	call   f010008b <_panic>

		*PT_entry = pa | perm |PTE_P;
f0100f8f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f92:	09 da                	or     %ebx,%edx
f0100f94:	89 10                	mov    %edx,(%eax)
		va += PGSIZE;
		pa += PGSIZE;
f0100f96:	81 c3 00 10 00 00    	add    $0x1000,%ebx
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	for(int i = 0; i < size/PGSIZE; i++){
f0100f9c:	83 c6 01             	add    $0x1,%esi
f0100f9f:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100fa2:	75 bc                	jne    f0100f60 <boot_map_region+0x2b>
		pte_t *pte = pgdir_walk(pgdir, (void *) va, 1);	//create
		if (!pte) panic("boot_map_region panic, out of memory");
		*pte = pa | perm | PTE_P;
	}
*/
}
f0100fa4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fa7:	5b                   	pop    %ebx
f0100fa8:	5e                   	pop    %esi
f0100fa9:	5f                   	pop    %edi
f0100faa:	5d                   	pop    %ebp
f0100fab:	c3                   	ret    

f0100fac <page_lookup>:
//

// existuje mapovanie pre virtualnu adresu danu na vstupe ?
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100fac:	55                   	push   %ebp
f0100fad:	89 e5                	mov    %esp,%ebp
f0100faf:	53                   	push   %ebx
f0100fb0:	83 ec 08             	sub    $0x8,%esp
f0100fb3:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *PT_entry = pgdir_walk(pgdir, va, 0);
f0100fb6:	6a 00                	push   $0x0
f0100fb8:	ff 75 0c             	pushl  0xc(%ebp)
f0100fbb:	ff 75 08             	pushl  0x8(%ebp)
f0100fbe:	e8 a5 fe ff ff       	call   f0100e68 <pgdir_walk>
	if (!PT_entry)
f0100fc3:	83 c4 10             	add    $0x10,%esp
f0100fc6:	85 c0                	test   %eax,%eax
f0100fc8:	74 32                	je     f0100ffc <page_lookup+0x50>
		return NULL;

	if (pte_store)
f0100fca:	85 db                	test   %ebx,%ebx
f0100fcc:	74 02                	je     f0100fd0 <page_lookup+0x24>
		*pte_store = PT_entry;
f0100fce:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fd0:	8b 00                	mov    (%eax),%eax
f0100fd2:	c1 e8 0c             	shr    $0xc,%eax
f0100fd5:	3b 05 48 79 11 f0    	cmp    0xf0117948,%eax
f0100fdb:	72 14                	jb     f0100ff1 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100fdd:	83 ec 04             	sub    $0x4,%esp
f0100fe0:	68 70 3d 10 f0       	push   $0xf0103d70
f0100fe5:	6a 4b                	push   $0x4b
f0100fe7:	68 de 43 10 f0       	push   $0xf01043de
f0100fec:	e8 9a f0 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100ff1:	8b 15 50 79 11 f0    	mov    0xf0117950,%edx
f0100ff7:	8d 04 c2             	lea    (%edx,%eax,8),%eax

	return (struct PageInfo*)pa2page(PTE_ADDR(*PT_entry));
f0100ffa:	eb 05                	jmp    f0101001 <page_lookup+0x55>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *PT_entry = pgdir_walk(pgdir, va, 0);
	if (!PT_entry)
		return NULL;
f0100ffc:	b8 00 00 00 00       	mov    $0x0,%eax
	if (pte_store)
		*pte_store = pte;	//found and set
	return pa2page(PTE_ADDR(*pte));	
*/
	return NULL;
}
f0101001:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101004:	c9                   	leave  
f0101005:	c3                   	ret    

f0101006 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101006:	55                   	push   %ebp
f0101007:	89 e5                	mov    %esp,%ebp
f0101009:	53                   	push   %ebx
f010100a:	83 ec 18             	sub    $0x18,%esp
f010100d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *PT_entry;
	struct PageInfo* page = page_lookup(pgdir, va, &PT_entry);
f0101010:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101013:	50                   	push   %eax
f0101014:	53                   	push   %ebx
f0101015:	ff 75 08             	pushl  0x8(%ebp)
f0101018:	e8 8f ff ff ff       	call   f0100fac <page_lookup>
	if (!page || !(*PT_entry & PTE_P)) 
f010101d:	83 c4 10             	add    $0x10,%esp
f0101020:	85 c0                	test   %eax,%eax
f0101022:	74 20                	je     f0101044 <page_remove+0x3e>
f0101024:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101027:	f6 02 01             	testb  $0x1,(%edx)
f010102a:	74 18                	je     f0101044 <page_remove+0x3e>
		return;

	page_decref(page);
f010102c:	83 ec 0c             	sub    $0xc,%esp
f010102f:	50                   	push   %eax
f0101030:	e8 0c fe ff ff       	call   f0100e41 <page_decref>
	*PT_entry = 0;
f0101035:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101038:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010103e:	0f 01 3b             	invlpg (%ebx)
f0101041:	83 c4 10             	add    $0x10,%esp
	*pte = 0;
//   - The TLB must be invalidated if you remove an entry from
//     the page table.
	tlb_invalidate(pgdir, va);
*/
}
f0101044:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101047:	c9                   	leave  
f0101048:	c3                   	ret    

f0101049 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101049:	55                   	push   %ebp
f010104a:	89 e5                	mov    %esp,%ebp
f010104c:	57                   	push   %edi
f010104d:	56                   	push   %esi
f010104e:	53                   	push   %ebx
f010104f:	83 ec 10             	sub    $0x10,%esp
f0101052:	8b 7d 0c             	mov    0xc(%ebp),%edi
	pte_t *PT_entry = pgdir_walk(pgdir, va, 1);
f0101055:	6a 01                	push   $0x1
f0101057:	ff 75 10             	pushl  0x10(%ebp)
f010105a:	ff 75 08             	pushl  0x8(%ebp)
f010105d:	e8 06 fe ff ff       	call   f0100e68 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101062:	89 fb                	mov    %edi,%ebx
f0101064:	2b 1d 50 79 11 f0    	sub    0xf0117950,%ebx
f010106a:	c1 fb 03             	sar    $0x3,%ebx
f010106d:	c1 e3 0c             	shl    $0xc,%ebx
	physaddr_t page_phaddr = page2pa(pp);

	if (!PT_entry)
f0101070:	83 c4 10             	add    $0x10,%esp
f0101073:	85 c0                	test   %eax,%eax
f0101075:	74 4f                	je     f01010c6 <page_insert+0x7d>
f0101077:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	
	if (*PT_entry & PTE_P) {
f0101079:	8b 00                	mov    (%eax),%eax
f010107b:	a8 01                	test   $0x1,%al
f010107d:	74 31                	je     f01010b0 <page_insert+0x67>
		if (page_phaddr == PTE_ADDR(*PT_entry)) {
f010107f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101084:	39 d8                	cmp    %ebx,%eax
f0101086:	75 11                	jne    f0101099 <page_insert+0x50>
			*PT_entry = page_phaddr | perm |PTE_P;
f0101088:	8b 55 14             	mov    0x14(%ebp),%edx
f010108b:	83 ca 01             	or     $0x1,%edx
f010108e:	09 d0                	or     %edx,%eax
f0101090:	89 06                	mov    %eax,(%esi)
			return 0;
f0101092:	b8 00 00 00 00       	mov    $0x0,%eax
f0101097:	eb 32                	jmp    f01010cb <page_insert+0x82>
f0101099:	8b 45 10             	mov    0x10(%ebp),%eax
f010109c:	0f 01 38             	invlpg (%eax)
		}

		tlb_invalidate(pgdir, va);
		page_remove(pgdir, va);
f010109f:	83 ec 08             	sub    $0x8,%esp
f01010a2:	ff 75 10             	pushl  0x10(%ebp)
f01010a5:	ff 75 08             	pushl  0x8(%ebp)
f01010a8:	e8 59 ff ff ff       	call   f0101006 <page_remove>
f01010ad:	83 c4 10             	add    $0x10,%esp
	}

	pp->pp_ref++;
f01010b0:	66 83 47 04 01       	addw   $0x1,0x4(%edi)
	*PT_entry = page_phaddr | perm |PTE_P;
f01010b5:	8b 45 14             	mov    0x14(%ebp),%eax
f01010b8:	83 c8 01             	or     $0x1,%eax
f01010bb:	09 c3                	or     %eax,%ebx
f01010bd:	89 1e                	mov    %ebx,(%esi)

	return 0;
f01010bf:	b8 00 00 00 00       	mov    $0x0,%eax
f01010c4:	eb 05                	jmp    f01010cb <page_insert+0x82>
{
	pte_t *PT_entry = pgdir_walk(pgdir, va, 1);
	physaddr_t page_phaddr = page2pa(pp);

	if (!PT_entry)
		return -E_NO_MEM;
f01010c6:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	pp->pp_ref++;	
	if (*pte & PTE_P) 	//page colides, tle is invalidated in page_remove
		page_remove(pgdir, va);
	*pte = page2pa(pp) | perm | PTE_P;
*/	return 0;
}
f01010cb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010ce:	5b                   	pop    %ebx
f01010cf:	5e                   	pop    %esi
f01010d0:	5f                   	pop    %edi
f01010d1:	5d                   	pop    %ebp
f01010d2:	c3                   	ret    

f01010d3 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01010d3:	55                   	push   %ebp
f01010d4:	89 e5                	mov    %esp,%ebp
f01010d6:	57                   	push   %edi
f01010d7:	56                   	push   %esi
f01010d8:	53                   	push   %ebx
f01010d9:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01010dc:	b8 15 00 00 00       	mov    $0x15,%eax
f01010e1:	e8 06 f8 ff ff       	call   f01008ec <nvram_read>
f01010e6:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01010e8:	b8 17 00 00 00       	mov    $0x17,%eax
f01010ed:	e8 fa f7 ff ff       	call   f01008ec <nvram_read>
f01010f2:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01010f4:	b8 34 00 00 00       	mov    $0x34,%eax
f01010f9:	e8 ee f7 ff ff       	call   f01008ec <nvram_read>
f01010fe:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0101101:	85 c0                	test   %eax,%eax
f0101103:	74 07                	je     f010110c <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0101105:	05 00 40 00 00       	add    $0x4000,%eax
f010110a:	eb 0b                	jmp    f0101117 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f010110c:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101112:	85 f6                	test   %esi,%esi
f0101114:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0101117:	89 c2                	mov    %eax,%edx
f0101119:	c1 ea 02             	shr    $0x2,%edx
f010111c:	89 15 48 79 11 f0    	mov    %edx,0xf0117948
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101122:	89 c2                	mov    %eax,%edx
f0101124:	29 da                	sub    %ebx,%edx
f0101126:	52                   	push   %edx
f0101127:	53                   	push   %ebx
f0101128:	50                   	push   %eax
f0101129:	68 90 3d 10 f0       	push   $0xf0103d90
f010112e:	e8 5a 16 00 00       	call   f010278d <cprintf>
	size_t n;

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();
	
	boot_alloc(0);
f0101133:	b8 00 00 00 00       	mov    $0x0,%eax
f0101138:	e8 3c f8 ff ff       	call   f0100979 <boot_alloc>
	boot_alloc(-10);		// nepanikari .. PRECO ??? 
f010113d:	b8 f6 ff ff ff       	mov    $0xfffffff6,%eax
f0101142:	e8 32 f8 ff ff       	call   f0100979 <boot_alloc>
	
//	panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101147:	b8 00 10 00 00       	mov    $0x1000,%eax
f010114c:	e8 28 f8 ff ff       	call   f0100979 <boot_alloc>
f0101151:	a3 4c 79 11 f0       	mov    %eax,0xf011794c
	memset(kern_pgdir, 0, PGSIZE);
f0101156:	83 c4 0c             	add    $0xc,%esp
f0101159:	68 00 10 00 00       	push   $0x1000
f010115e:	6a 00                	push   $0x0
f0101160:	50                   	push   %eax
f0101161:	e8 e0 20 00 00       	call   f0103246 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101166:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010116b:	83 c4 10             	add    $0x10,%esp
f010116e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101173:	77 15                	ja     f010118a <mem_init+0xb7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101175:	50                   	push   %eax
f0101176:	68 08 3c 10 f0       	push   $0xf0103c08
f010117b:	68 ca 00 00 00       	push   $0xca
f0101180:	68 b8 43 10 f0       	push   $0xf01043b8
f0101185:	e8 01 ef ff ff       	call   f010008b <_panic>
f010118a:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101190:	83 ca 05             	or     $0x5,%edx
f0101193:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
// pages je pole pointerov na strukturu PageInfo
// boot_alloc alokuje pamat pre vsetky npages velkosti PageInfo
// boot_alloc vrati (void*) adresu prvej volnej stranky, ktora ukazuje na dalsiu ...
// treba vobec pretypovavat ??
// memsetujeme od pages po vsetky stranky (x ich velkost) => memsetujeme vsetko
	pages = boot_alloc(npages*sizeof(struct PageInfo));
f0101199:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f010119e:	c1 e0 03             	shl    $0x3,%eax
f01011a1:	e8 d3 f7 ff ff       	call   f0100979 <boot_alloc>
f01011a6:	a3 50 79 11 f0       	mov    %eax,0xf0117950
	memset(pages, 0, npages * sizeof(struct PageInfo));
f01011ab:	83 ec 04             	sub    $0x4,%esp
f01011ae:	8b 0d 48 79 11 f0    	mov    0xf0117948,%ecx
f01011b4:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01011bb:	52                   	push   %edx
f01011bc:	6a 00                	push   $0x0
f01011be:	50                   	push   %eax
f01011bf:	e8 82 20 00 00       	call   f0103246 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01011c4:	e8 02 fb ff ff       	call   f0100ccb <page_init>

	check_page_free_list(1);
f01011c9:	b8 01 00 00 00       	mov    $0x1,%eax
f01011ce:	e8 35 f8 ff ff       	call   f0100a08 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011d3:	83 c4 10             	add    $0x10,%esp
f01011d6:	83 3d 50 79 11 f0 00 	cmpl   $0x0,0xf0117950
f01011dd:	75 17                	jne    f01011f6 <mem_init+0x123>
		panic("'pages' is a null pointer!");
f01011df:	83 ec 04             	sub    $0x4,%esp
f01011e2:	68 88 44 10 f0       	push   $0xf0104488
f01011e7:	68 1e 03 00 00       	push   $0x31e
f01011ec:	68 b8 43 10 f0       	push   $0xf01043b8
f01011f1:	e8 95 ee ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011f6:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01011fb:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101200:	eb 05                	jmp    f0101207 <mem_init+0x134>
		++nfree;
f0101202:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101205:	8b 00                	mov    (%eax),%eax
f0101207:	85 c0                	test   %eax,%eax
f0101209:	75 f7                	jne    f0101202 <mem_init+0x12f>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010120b:	83 ec 0c             	sub    $0xc,%esp
f010120e:	6a 00                	push   $0x0
f0101210:	e8 81 fb ff ff       	call   f0100d96 <page_alloc>
f0101215:	89 c7                	mov    %eax,%edi
f0101217:	83 c4 10             	add    $0x10,%esp
f010121a:	85 c0                	test   %eax,%eax
f010121c:	75 19                	jne    f0101237 <mem_init+0x164>
f010121e:	68 a3 44 10 f0       	push   $0xf01044a3
f0101223:	68 f8 43 10 f0       	push   $0xf01043f8
f0101228:	68 26 03 00 00       	push   $0x326
f010122d:	68 b8 43 10 f0       	push   $0xf01043b8
f0101232:	e8 54 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101237:	83 ec 0c             	sub    $0xc,%esp
f010123a:	6a 00                	push   $0x0
f010123c:	e8 55 fb ff ff       	call   f0100d96 <page_alloc>
f0101241:	89 c6                	mov    %eax,%esi
f0101243:	83 c4 10             	add    $0x10,%esp
f0101246:	85 c0                	test   %eax,%eax
f0101248:	75 19                	jne    f0101263 <mem_init+0x190>
f010124a:	68 b9 44 10 f0       	push   $0xf01044b9
f010124f:	68 f8 43 10 f0       	push   $0xf01043f8
f0101254:	68 27 03 00 00       	push   $0x327
f0101259:	68 b8 43 10 f0       	push   $0xf01043b8
f010125e:	e8 28 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101263:	83 ec 0c             	sub    $0xc,%esp
f0101266:	6a 00                	push   $0x0
f0101268:	e8 29 fb ff ff       	call   f0100d96 <page_alloc>
f010126d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101270:	83 c4 10             	add    $0x10,%esp
f0101273:	85 c0                	test   %eax,%eax
f0101275:	75 19                	jne    f0101290 <mem_init+0x1bd>
f0101277:	68 cf 44 10 f0       	push   $0xf01044cf
f010127c:	68 f8 43 10 f0       	push   $0xf01043f8
f0101281:	68 28 03 00 00       	push   $0x328
f0101286:	68 b8 43 10 f0       	push   $0xf01043b8
f010128b:	e8 fb ed ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101290:	39 f7                	cmp    %esi,%edi
f0101292:	75 19                	jne    f01012ad <mem_init+0x1da>
f0101294:	68 e5 44 10 f0       	push   $0xf01044e5
f0101299:	68 f8 43 10 f0       	push   $0xf01043f8
f010129e:	68 2b 03 00 00       	push   $0x32b
f01012a3:	68 b8 43 10 f0       	push   $0xf01043b8
f01012a8:	e8 de ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01012ad:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012b0:	39 c6                	cmp    %eax,%esi
f01012b2:	74 04                	je     f01012b8 <mem_init+0x1e5>
f01012b4:	39 c7                	cmp    %eax,%edi
f01012b6:	75 19                	jne    f01012d1 <mem_init+0x1fe>
f01012b8:	68 cc 3d 10 f0       	push   $0xf0103dcc
f01012bd:	68 f8 43 10 f0       	push   $0xf01043f8
f01012c2:	68 2c 03 00 00       	push   $0x32c
f01012c7:	68 b8 43 10 f0       	push   $0xf01043b8
f01012cc:	e8 ba ed ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012d1:	8b 0d 50 79 11 f0    	mov    0xf0117950,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01012d7:	8b 15 48 79 11 f0    	mov    0xf0117948,%edx
f01012dd:	c1 e2 0c             	shl    $0xc,%edx
f01012e0:	89 f8                	mov    %edi,%eax
f01012e2:	29 c8                	sub    %ecx,%eax
f01012e4:	c1 f8 03             	sar    $0x3,%eax
f01012e7:	c1 e0 0c             	shl    $0xc,%eax
f01012ea:	39 d0                	cmp    %edx,%eax
f01012ec:	72 19                	jb     f0101307 <mem_init+0x234>
f01012ee:	68 f7 44 10 f0       	push   $0xf01044f7
f01012f3:	68 f8 43 10 f0       	push   $0xf01043f8
f01012f8:	68 2d 03 00 00       	push   $0x32d
f01012fd:	68 b8 43 10 f0       	push   $0xf01043b8
f0101302:	e8 84 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101307:	89 f0                	mov    %esi,%eax
f0101309:	29 c8                	sub    %ecx,%eax
f010130b:	c1 f8 03             	sar    $0x3,%eax
f010130e:	c1 e0 0c             	shl    $0xc,%eax
f0101311:	39 c2                	cmp    %eax,%edx
f0101313:	77 19                	ja     f010132e <mem_init+0x25b>
f0101315:	68 14 45 10 f0       	push   $0xf0104514
f010131a:	68 f8 43 10 f0       	push   $0xf01043f8
f010131f:	68 2e 03 00 00       	push   $0x32e
f0101324:	68 b8 43 10 f0       	push   $0xf01043b8
f0101329:	e8 5d ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010132e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101331:	29 c8                	sub    %ecx,%eax
f0101333:	c1 f8 03             	sar    $0x3,%eax
f0101336:	c1 e0 0c             	shl    $0xc,%eax
f0101339:	39 c2                	cmp    %eax,%edx
f010133b:	77 19                	ja     f0101356 <mem_init+0x283>
f010133d:	68 31 45 10 f0       	push   $0xf0104531
f0101342:	68 f8 43 10 f0       	push   $0xf01043f8
f0101347:	68 2f 03 00 00       	push   $0x32f
f010134c:	68 b8 43 10 f0       	push   $0xf01043b8
f0101351:	e8 35 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101356:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010135b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010135e:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101365:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101368:	83 ec 0c             	sub    $0xc,%esp
f010136b:	6a 00                	push   $0x0
f010136d:	e8 24 fa ff ff       	call   f0100d96 <page_alloc>
f0101372:	83 c4 10             	add    $0x10,%esp
f0101375:	85 c0                	test   %eax,%eax
f0101377:	74 19                	je     f0101392 <mem_init+0x2bf>
f0101379:	68 4e 45 10 f0       	push   $0xf010454e
f010137e:	68 f8 43 10 f0       	push   $0xf01043f8
f0101383:	68 36 03 00 00       	push   $0x336
f0101388:	68 b8 43 10 f0       	push   $0xf01043b8
f010138d:	e8 f9 ec ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101392:	83 ec 0c             	sub    $0xc,%esp
f0101395:	57                   	push   %edi
f0101396:	e8 6b fa ff ff       	call   f0100e06 <page_free>
	page_free(pp1);
f010139b:	89 34 24             	mov    %esi,(%esp)
f010139e:	e8 63 fa ff ff       	call   f0100e06 <page_free>
	page_free(pp2);
f01013a3:	83 c4 04             	add    $0x4,%esp
f01013a6:	ff 75 d4             	pushl  -0x2c(%ebp)
f01013a9:	e8 58 fa ff ff       	call   f0100e06 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013ae:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013b5:	e8 dc f9 ff ff       	call   f0100d96 <page_alloc>
f01013ba:	89 c6                	mov    %eax,%esi
f01013bc:	83 c4 10             	add    $0x10,%esp
f01013bf:	85 c0                	test   %eax,%eax
f01013c1:	75 19                	jne    f01013dc <mem_init+0x309>
f01013c3:	68 a3 44 10 f0       	push   $0xf01044a3
f01013c8:	68 f8 43 10 f0       	push   $0xf01043f8
f01013cd:	68 3d 03 00 00       	push   $0x33d
f01013d2:	68 b8 43 10 f0       	push   $0xf01043b8
f01013d7:	e8 af ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01013dc:	83 ec 0c             	sub    $0xc,%esp
f01013df:	6a 00                	push   $0x0
f01013e1:	e8 b0 f9 ff ff       	call   f0100d96 <page_alloc>
f01013e6:	89 c7                	mov    %eax,%edi
f01013e8:	83 c4 10             	add    $0x10,%esp
f01013eb:	85 c0                	test   %eax,%eax
f01013ed:	75 19                	jne    f0101408 <mem_init+0x335>
f01013ef:	68 b9 44 10 f0       	push   $0xf01044b9
f01013f4:	68 f8 43 10 f0       	push   $0xf01043f8
f01013f9:	68 3e 03 00 00       	push   $0x33e
f01013fe:	68 b8 43 10 f0       	push   $0xf01043b8
f0101403:	e8 83 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101408:	83 ec 0c             	sub    $0xc,%esp
f010140b:	6a 00                	push   $0x0
f010140d:	e8 84 f9 ff ff       	call   f0100d96 <page_alloc>
f0101412:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101415:	83 c4 10             	add    $0x10,%esp
f0101418:	85 c0                	test   %eax,%eax
f010141a:	75 19                	jne    f0101435 <mem_init+0x362>
f010141c:	68 cf 44 10 f0       	push   $0xf01044cf
f0101421:	68 f8 43 10 f0       	push   $0xf01043f8
f0101426:	68 3f 03 00 00       	push   $0x33f
f010142b:	68 b8 43 10 f0       	push   $0xf01043b8
f0101430:	e8 56 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101435:	39 fe                	cmp    %edi,%esi
f0101437:	75 19                	jne    f0101452 <mem_init+0x37f>
f0101439:	68 e5 44 10 f0       	push   $0xf01044e5
f010143e:	68 f8 43 10 f0       	push   $0xf01043f8
f0101443:	68 41 03 00 00       	push   $0x341
f0101448:	68 b8 43 10 f0       	push   $0xf01043b8
f010144d:	e8 39 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101452:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101455:	39 c6                	cmp    %eax,%esi
f0101457:	74 04                	je     f010145d <mem_init+0x38a>
f0101459:	39 c7                	cmp    %eax,%edi
f010145b:	75 19                	jne    f0101476 <mem_init+0x3a3>
f010145d:	68 cc 3d 10 f0       	push   $0xf0103dcc
f0101462:	68 f8 43 10 f0       	push   $0xf01043f8
f0101467:	68 42 03 00 00       	push   $0x342
f010146c:	68 b8 43 10 f0       	push   $0xf01043b8
f0101471:	e8 15 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101476:	83 ec 0c             	sub    $0xc,%esp
f0101479:	6a 00                	push   $0x0
f010147b:	e8 16 f9 ff ff       	call   f0100d96 <page_alloc>
f0101480:	83 c4 10             	add    $0x10,%esp
f0101483:	85 c0                	test   %eax,%eax
f0101485:	74 19                	je     f01014a0 <mem_init+0x3cd>
f0101487:	68 4e 45 10 f0       	push   $0xf010454e
f010148c:	68 f8 43 10 f0       	push   $0xf01043f8
f0101491:	68 43 03 00 00       	push   $0x343
f0101496:	68 b8 43 10 f0       	push   $0xf01043b8
f010149b:	e8 eb eb ff ff       	call   f010008b <_panic>
f01014a0:	89 f0                	mov    %esi,%eax
f01014a2:	2b 05 50 79 11 f0    	sub    0xf0117950,%eax
f01014a8:	c1 f8 03             	sar    $0x3,%eax
f01014ab:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014ae:	89 c2                	mov    %eax,%edx
f01014b0:	c1 ea 0c             	shr    $0xc,%edx
f01014b3:	3b 15 48 79 11 f0    	cmp    0xf0117948,%edx
f01014b9:	72 12                	jb     f01014cd <mem_init+0x3fa>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014bb:	50                   	push   %eax
f01014bc:	68 e4 3b 10 f0       	push   $0xf0103be4
f01014c1:	6a 52                	push   $0x52
f01014c3:	68 de 43 10 f0       	push   $0xf01043de
f01014c8:	e8 be eb ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01014cd:	83 ec 04             	sub    $0x4,%esp
f01014d0:	68 00 10 00 00       	push   $0x1000
f01014d5:	6a 01                	push   $0x1
f01014d7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014dc:	50                   	push   %eax
f01014dd:	e8 64 1d 00 00       	call   f0103246 <memset>
	page_free(pp0);
f01014e2:	89 34 24             	mov    %esi,(%esp)
f01014e5:	e8 1c f9 ff ff       	call   f0100e06 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014ea:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014f1:	e8 a0 f8 ff ff       	call   f0100d96 <page_alloc>
f01014f6:	83 c4 10             	add    $0x10,%esp
f01014f9:	85 c0                	test   %eax,%eax
f01014fb:	75 19                	jne    f0101516 <mem_init+0x443>
f01014fd:	68 5d 45 10 f0       	push   $0xf010455d
f0101502:	68 f8 43 10 f0       	push   $0xf01043f8
f0101507:	68 48 03 00 00       	push   $0x348
f010150c:	68 b8 43 10 f0       	push   $0xf01043b8
f0101511:	e8 75 eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101516:	39 c6                	cmp    %eax,%esi
f0101518:	74 19                	je     f0101533 <mem_init+0x460>
f010151a:	68 7b 45 10 f0       	push   $0xf010457b
f010151f:	68 f8 43 10 f0       	push   $0xf01043f8
f0101524:	68 49 03 00 00       	push   $0x349
f0101529:	68 b8 43 10 f0       	push   $0xf01043b8
f010152e:	e8 58 eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101533:	89 f0                	mov    %esi,%eax
f0101535:	2b 05 50 79 11 f0    	sub    0xf0117950,%eax
f010153b:	c1 f8 03             	sar    $0x3,%eax
f010153e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101541:	89 c2                	mov    %eax,%edx
f0101543:	c1 ea 0c             	shr    $0xc,%edx
f0101546:	3b 15 48 79 11 f0    	cmp    0xf0117948,%edx
f010154c:	72 12                	jb     f0101560 <mem_init+0x48d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010154e:	50                   	push   %eax
f010154f:	68 e4 3b 10 f0       	push   $0xf0103be4
f0101554:	6a 52                	push   $0x52
f0101556:	68 de 43 10 f0       	push   $0xf01043de
f010155b:	e8 2b eb ff ff       	call   f010008b <_panic>
f0101560:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101566:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010156c:	80 38 00             	cmpb   $0x0,(%eax)
f010156f:	74 19                	je     f010158a <mem_init+0x4b7>
f0101571:	68 8b 45 10 f0       	push   $0xf010458b
f0101576:	68 f8 43 10 f0       	push   $0xf01043f8
f010157b:	68 4c 03 00 00       	push   $0x34c
f0101580:	68 b8 43 10 f0       	push   $0xf01043b8
f0101585:	e8 01 eb ff ff       	call   f010008b <_panic>
f010158a:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010158d:	39 d0                	cmp    %edx,%eax
f010158f:	75 db                	jne    f010156c <mem_init+0x499>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101591:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101594:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f0101599:	83 ec 0c             	sub    $0xc,%esp
f010159c:	56                   	push   %esi
f010159d:	e8 64 f8 ff ff       	call   f0100e06 <page_free>
	page_free(pp1);
f01015a2:	89 3c 24             	mov    %edi,(%esp)
f01015a5:	e8 5c f8 ff ff       	call   f0100e06 <page_free>
	page_free(pp2);
f01015aa:	83 c4 04             	add    $0x4,%esp
f01015ad:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015b0:	e8 51 f8 ff ff       	call   f0100e06 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015b5:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01015ba:	83 c4 10             	add    $0x10,%esp
f01015bd:	eb 05                	jmp    f01015c4 <mem_init+0x4f1>
		--nfree;
f01015bf:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015c2:	8b 00                	mov    (%eax),%eax
f01015c4:	85 c0                	test   %eax,%eax
f01015c6:	75 f7                	jne    f01015bf <mem_init+0x4ec>
		--nfree;
	assert(nfree == 0);
f01015c8:	85 db                	test   %ebx,%ebx
f01015ca:	74 19                	je     f01015e5 <mem_init+0x512>
f01015cc:	68 95 45 10 f0       	push   $0xf0104595
f01015d1:	68 f8 43 10 f0       	push   $0xf01043f8
f01015d6:	68 59 03 00 00       	push   $0x359
f01015db:	68 b8 43 10 f0       	push   $0xf01043b8
f01015e0:	e8 a6 ea ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015e5:	83 ec 0c             	sub    $0xc,%esp
f01015e8:	68 ec 3d 10 f0       	push   $0xf0103dec
f01015ed:	e8 9b 11 00 00       	call   f010278d <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015f2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015f9:	e8 98 f7 ff ff       	call   f0100d96 <page_alloc>
f01015fe:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101601:	83 c4 10             	add    $0x10,%esp
f0101604:	85 c0                	test   %eax,%eax
f0101606:	75 19                	jne    f0101621 <mem_init+0x54e>
f0101608:	68 a3 44 10 f0       	push   $0xf01044a3
f010160d:	68 f8 43 10 f0       	push   $0xf01043f8
f0101612:	68 b2 03 00 00       	push   $0x3b2
f0101617:	68 b8 43 10 f0       	push   $0xf01043b8
f010161c:	e8 6a ea ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101621:	83 ec 0c             	sub    $0xc,%esp
f0101624:	6a 00                	push   $0x0
f0101626:	e8 6b f7 ff ff       	call   f0100d96 <page_alloc>
f010162b:	89 c3                	mov    %eax,%ebx
f010162d:	83 c4 10             	add    $0x10,%esp
f0101630:	85 c0                	test   %eax,%eax
f0101632:	75 19                	jne    f010164d <mem_init+0x57a>
f0101634:	68 b9 44 10 f0       	push   $0xf01044b9
f0101639:	68 f8 43 10 f0       	push   $0xf01043f8
f010163e:	68 b3 03 00 00       	push   $0x3b3
f0101643:	68 b8 43 10 f0       	push   $0xf01043b8
f0101648:	e8 3e ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010164d:	83 ec 0c             	sub    $0xc,%esp
f0101650:	6a 00                	push   $0x0
f0101652:	e8 3f f7 ff ff       	call   f0100d96 <page_alloc>
f0101657:	89 c6                	mov    %eax,%esi
f0101659:	83 c4 10             	add    $0x10,%esp
f010165c:	85 c0                	test   %eax,%eax
f010165e:	75 19                	jne    f0101679 <mem_init+0x5a6>
f0101660:	68 cf 44 10 f0       	push   $0xf01044cf
f0101665:	68 f8 43 10 f0       	push   $0xf01043f8
f010166a:	68 b4 03 00 00       	push   $0x3b4
f010166f:	68 b8 43 10 f0       	push   $0xf01043b8
f0101674:	e8 12 ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101679:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010167c:	75 19                	jne    f0101697 <mem_init+0x5c4>
f010167e:	68 e5 44 10 f0       	push   $0xf01044e5
f0101683:	68 f8 43 10 f0       	push   $0xf01043f8
f0101688:	68 b7 03 00 00       	push   $0x3b7
f010168d:	68 b8 43 10 f0       	push   $0xf01043b8
f0101692:	e8 f4 e9 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101697:	39 c3                	cmp    %eax,%ebx
f0101699:	74 05                	je     f01016a0 <mem_init+0x5cd>
f010169b:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010169e:	75 19                	jne    f01016b9 <mem_init+0x5e6>
f01016a0:	68 cc 3d 10 f0       	push   $0xf0103dcc
f01016a5:	68 f8 43 10 f0       	push   $0xf01043f8
f01016aa:	68 b8 03 00 00       	push   $0x3b8
f01016af:	68 b8 43 10 f0       	push   $0xf01043b8
f01016b4:	e8 d2 e9 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016b9:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01016be:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016c1:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01016c8:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016cb:	83 ec 0c             	sub    $0xc,%esp
f01016ce:	6a 00                	push   $0x0
f01016d0:	e8 c1 f6 ff ff       	call   f0100d96 <page_alloc>
f01016d5:	83 c4 10             	add    $0x10,%esp
f01016d8:	85 c0                	test   %eax,%eax
f01016da:	74 19                	je     f01016f5 <mem_init+0x622>
f01016dc:	68 4e 45 10 f0       	push   $0xf010454e
f01016e1:	68 f8 43 10 f0       	push   $0xf01043f8
f01016e6:	68 bf 03 00 00       	push   $0x3bf
f01016eb:	68 b8 43 10 f0       	push   $0xf01043b8
f01016f0:	e8 96 e9 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01016f5:	83 ec 04             	sub    $0x4,%esp
f01016f8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016fb:	50                   	push   %eax
f01016fc:	6a 00                	push   $0x0
f01016fe:	ff 35 4c 79 11 f0    	pushl  0xf011794c
f0101704:	e8 a3 f8 ff ff       	call   f0100fac <page_lookup>
f0101709:	83 c4 10             	add    $0x10,%esp
f010170c:	85 c0                	test   %eax,%eax
f010170e:	74 19                	je     f0101729 <mem_init+0x656>
f0101710:	68 0c 3e 10 f0       	push   $0xf0103e0c
f0101715:	68 f8 43 10 f0       	push   $0xf01043f8
f010171a:	68 c2 03 00 00       	push   $0x3c2
f010171f:	68 b8 43 10 f0       	push   $0xf01043b8
f0101724:	e8 62 e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101729:	6a 02                	push   $0x2
f010172b:	6a 00                	push   $0x0
f010172d:	53                   	push   %ebx
f010172e:	ff 35 4c 79 11 f0    	pushl  0xf011794c
f0101734:	e8 10 f9 ff ff       	call   f0101049 <page_insert>
f0101739:	83 c4 10             	add    $0x10,%esp
f010173c:	85 c0                	test   %eax,%eax
f010173e:	78 19                	js     f0101759 <mem_init+0x686>
f0101740:	68 44 3e 10 f0       	push   $0xf0103e44
f0101745:	68 f8 43 10 f0       	push   $0xf01043f8
f010174a:	68 c5 03 00 00       	push   $0x3c5
f010174f:	68 b8 43 10 f0       	push   $0xf01043b8
f0101754:	e8 32 e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101759:	83 ec 0c             	sub    $0xc,%esp
f010175c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010175f:	e8 a2 f6 ff ff       	call   f0100e06 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101764:	6a 02                	push   $0x2
f0101766:	6a 00                	push   $0x0
f0101768:	53                   	push   %ebx
f0101769:	ff 35 4c 79 11 f0    	pushl  0xf011794c
f010176f:	e8 d5 f8 ff ff       	call   f0101049 <page_insert>
f0101774:	83 c4 20             	add    $0x20,%esp
f0101777:	85 c0                	test   %eax,%eax
f0101779:	74 19                	je     f0101794 <mem_init+0x6c1>
f010177b:	68 74 3e 10 f0       	push   $0xf0103e74
f0101780:	68 f8 43 10 f0       	push   $0xf01043f8
f0101785:	68 c9 03 00 00       	push   $0x3c9
f010178a:	68 b8 43 10 f0       	push   $0xf01043b8
f010178f:	e8 f7 e8 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101794:	8b 3d 4c 79 11 f0    	mov    0xf011794c,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010179a:	a1 50 79 11 f0       	mov    0xf0117950,%eax
f010179f:	89 c1                	mov    %eax,%ecx
f01017a1:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01017a4:	8b 17                	mov    (%edi),%edx
f01017a6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01017ac:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017af:	29 c8                	sub    %ecx,%eax
f01017b1:	c1 f8 03             	sar    $0x3,%eax
f01017b4:	c1 e0 0c             	shl    $0xc,%eax
f01017b7:	39 c2                	cmp    %eax,%edx
f01017b9:	74 19                	je     f01017d4 <mem_init+0x701>
f01017bb:	68 a4 3e 10 f0       	push   $0xf0103ea4
f01017c0:	68 f8 43 10 f0       	push   $0xf01043f8
f01017c5:	68 ca 03 00 00       	push   $0x3ca
f01017ca:	68 b8 43 10 f0       	push   $0xf01043b8
f01017cf:	e8 b7 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01017d4:	ba 00 00 00 00       	mov    $0x0,%edx
f01017d9:	89 f8                	mov    %edi,%eax
f01017db:	e8 35 f1 ff ff       	call   f0100915 <check_va2pa>
f01017e0:	89 da                	mov    %ebx,%edx
f01017e2:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01017e5:	c1 fa 03             	sar    $0x3,%edx
f01017e8:	c1 e2 0c             	shl    $0xc,%edx
f01017eb:	39 d0                	cmp    %edx,%eax
f01017ed:	74 19                	je     f0101808 <mem_init+0x735>
f01017ef:	68 cc 3e 10 f0       	push   $0xf0103ecc
f01017f4:	68 f8 43 10 f0       	push   $0xf01043f8
f01017f9:	68 cb 03 00 00       	push   $0x3cb
f01017fe:	68 b8 43 10 f0       	push   $0xf01043b8
f0101803:	e8 83 e8 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101808:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010180d:	74 19                	je     f0101828 <mem_init+0x755>
f010180f:	68 a0 45 10 f0       	push   $0xf01045a0
f0101814:	68 f8 43 10 f0       	push   $0xf01043f8
f0101819:	68 cc 03 00 00       	push   $0x3cc
f010181e:	68 b8 43 10 f0       	push   $0xf01043b8
f0101823:	e8 63 e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f0101828:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010182b:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101830:	74 19                	je     f010184b <mem_init+0x778>
f0101832:	68 b1 45 10 f0       	push   $0xf01045b1
f0101837:	68 f8 43 10 f0       	push   $0xf01043f8
f010183c:	68 cd 03 00 00       	push   $0x3cd
f0101841:	68 b8 43 10 f0       	push   $0xf01043b8
f0101846:	e8 40 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010184b:	6a 02                	push   $0x2
f010184d:	68 00 10 00 00       	push   $0x1000
f0101852:	56                   	push   %esi
f0101853:	57                   	push   %edi
f0101854:	e8 f0 f7 ff ff       	call   f0101049 <page_insert>
f0101859:	83 c4 10             	add    $0x10,%esp
f010185c:	85 c0                	test   %eax,%eax
f010185e:	74 19                	je     f0101879 <mem_init+0x7a6>
f0101860:	68 fc 3e 10 f0       	push   $0xf0103efc
f0101865:	68 f8 43 10 f0       	push   $0xf01043f8
f010186a:	68 d0 03 00 00       	push   $0x3d0
f010186f:	68 b8 43 10 f0       	push   $0xf01043b8
f0101874:	e8 12 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101879:	ba 00 10 00 00       	mov    $0x1000,%edx
f010187e:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f0101883:	e8 8d f0 ff ff       	call   f0100915 <check_va2pa>
f0101888:	89 f2                	mov    %esi,%edx
f010188a:	2b 15 50 79 11 f0    	sub    0xf0117950,%edx
f0101890:	c1 fa 03             	sar    $0x3,%edx
f0101893:	c1 e2 0c             	shl    $0xc,%edx
f0101896:	39 d0                	cmp    %edx,%eax
f0101898:	74 19                	je     f01018b3 <mem_init+0x7e0>
f010189a:	68 38 3f 10 f0       	push   $0xf0103f38
f010189f:	68 f8 43 10 f0       	push   $0xf01043f8
f01018a4:	68 d1 03 00 00       	push   $0x3d1
f01018a9:	68 b8 43 10 f0       	push   $0xf01043b8
f01018ae:	e8 d8 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01018b3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018b8:	74 19                	je     f01018d3 <mem_init+0x800>
f01018ba:	68 c2 45 10 f0       	push   $0xf01045c2
f01018bf:	68 f8 43 10 f0       	push   $0xf01043f8
f01018c4:	68 d2 03 00 00       	push   $0x3d2
f01018c9:	68 b8 43 10 f0       	push   $0xf01043b8
f01018ce:	e8 b8 e7 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01018d3:	83 ec 0c             	sub    $0xc,%esp
f01018d6:	6a 00                	push   $0x0
f01018d8:	e8 b9 f4 ff ff       	call   f0100d96 <page_alloc>
f01018dd:	83 c4 10             	add    $0x10,%esp
f01018e0:	85 c0                	test   %eax,%eax
f01018e2:	74 19                	je     f01018fd <mem_init+0x82a>
f01018e4:	68 4e 45 10 f0       	push   $0xf010454e
f01018e9:	68 f8 43 10 f0       	push   $0xf01043f8
f01018ee:	68 d5 03 00 00       	push   $0x3d5
f01018f3:	68 b8 43 10 f0       	push   $0xf01043b8
f01018f8:	e8 8e e7 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018fd:	6a 02                	push   $0x2
f01018ff:	68 00 10 00 00       	push   $0x1000
f0101904:	56                   	push   %esi
f0101905:	ff 35 4c 79 11 f0    	pushl  0xf011794c
f010190b:	e8 39 f7 ff ff       	call   f0101049 <page_insert>
f0101910:	83 c4 10             	add    $0x10,%esp
f0101913:	85 c0                	test   %eax,%eax
f0101915:	74 19                	je     f0101930 <mem_init+0x85d>
f0101917:	68 fc 3e 10 f0       	push   $0xf0103efc
f010191c:	68 f8 43 10 f0       	push   $0xf01043f8
f0101921:	68 d8 03 00 00       	push   $0x3d8
f0101926:	68 b8 43 10 f0       	push   $0xf01043b8
f010192b:	e8 5b e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101930:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101935:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f010193a:	e8 d6 ef ff ff       	call   f0100915 <check_va2pa>
f010193f:	89 f2                	mov    %esi,%edx
f0101941:	2b 15 50 79 11 f0    	sub    0xf0117950,%edx
f0101947:	c1 fa 03             	sar    $0x3,%edx
f010194a:	c1 e2 0c             	shl    $0xc,%edx
f010194d:	39 d0                	cmp    %edx,%eax
f010194f:	74 19                	je     f010196a <mem_init+0x897>
f0101951:	68 38 3f 10 f0       	push   $0xf0103f38
f0101956:	68 f8 43 10 f0       	push   $0xf01043f8
f010195b:	68 d9 03 00 00       	push   $0x3d9
f0101960:	68 b8 43 10 f0       	push   $0xf01043b8
f0101965:	e8 21 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010196a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010196f:	74 19                	je     f010198a <mem_init+0x8b7>
f0101971:	68 c2 45 10 f0       	push   $0xf01045c2
f0101976:	68 f8 43 10 f0       	push   $0xf01043f8
f010197b:	68 da 03 00 00       	push   $0x3da
f0101980:	68 b8 43 10 f0       	push   $0xf01043b8
f0101985:	e8 01 e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f010198a:	83 ec 0c             	sub    $0xc,%esp
f010198d:	6a 00                	push   $0x0
f010198f:	e8 02 f4 ff ff       	call   f0100d96 <page_alloc>
f0101994:	83 c4 10             	add    $0x10,%esp
f0101997:	85 c0                	test   %eax,%eax
f0101999:	74 19                	je     f01019b4 <mem_init+0x8e1>
f010199b:	68 4e 45 10 f0       	push   $0xf010454e
f01019a0:	68 f8 43 10 f0       	push   $0xf01043f8
f01019a5:	68 de 03 00 00       	push   $0x3de
f01019aa:	68 b8 43 10 f0       	push   $0xf01043b8
f01019af:	e8 d7 e6 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01019b4:	8b 15 4c 79 11 f0    	mov    0xf011794c,%edx
f01019ba:	8b 02                	mov    (%edx),%eax
f01019bc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019c1:	89 c1                	mov    %eax,%ecx
f01019c3:	c1 e9 0c             	shr    $0xc,%ecx
f01019c6:	3b 0d 48 79 11 f0    	cmp    0xf0117948,%ecx
f01019cc:	72 15                	jb     f01019e3 <mem_init+0x910>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019ce:	50                   	push   %eax
f01019cf:	68 e4 3b 10 f0       	push   $0xf0103be4
f01019d4:	68 e1 03 00 00       	push   $0x3e1
f01019d9:	68 b8 43 10 f0       	push   $0xf01043b8
f01019de:	e8 a8 e6 ff ff       	call   f010008b <_panic>
f01019e3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019e8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01019eb:	83 ec 04             	sub    $0x4,%esp
f01019ee:	6a 00                	push   $0x0
f01019f0:	68 00 10 00 00       	push   $0x1000
f01019f5:	52                   	push   %edx
f01019f6:	e8 6d f4 ff ff       	call   f0100e68 <pgdir_walk>
f01019fb:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01019fe:	8d 51 04             	lea    0x4(%ecx),%edx
f0101a01:	83 c4 10             	add    $0x10,%esp
f0101a04:	39 d0                	cmp    %edx,%eax
f0101a06:	74 19                	je     f0101a21 <mem_init+0x94e>
f0101a08:	68 68 3f 10 f0       	push   $0xf0103f68
f0101a0d:	68 f8 43 10 f0       	push   $0xf01043f8
f0101a12:	68 e2 03 00 00       	push   $0x3e2
f0101a17:	68 b8 43 10 f0       	push   $0xf01043b8
f0101a1c:	e8 6a e6 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101a21:	6a 06                	push   $0x6
f0101a23:	68 00 10 00 00       	push   $0x1000
f0101a28:	56                   	push   %esi
f0101a29:	ff 35 4c 79 11 f0    	pushl  0xf011794c
f0101a2f:	e8 15 f6 ff ff       	call   f0101049 <page_insert>
f0101a34:	83 c4 10             	add    $0x10,%esp
f0101a37:	85 c0                	test   %eax,%eax
f0101a39:	74 19                	je     f0101a54 <mem_init+0x981>
f0101a3b:	68 a8 3f 10 f0       	push   $0xf0103fa8
f0101a40:	68 f8 43 10 f0       	push   $0xf01043f8
f0101a45:	68 e5 03 00 00       	push   $0x3e5
f0101a4a:	68 b8 43 10 f0       	push   $0xf01043b8
f0101a4f:	e8 37 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a54:	8b 3d 4c 79 11 f0    	mov    0xf011794c,%edi
f0101a5a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a5f:	89 f8                	mov    %edi,%eax
f0101a61:	e8 af ee ff ff       	call   f0100915 <check_va2pa>
f0101a66:	89 f2                	mov    %esi,%edx
f0101a68:	2b 15 50 79 11 f0    	sub    0xf0117950,%edx
f0101a6e:	c1 fa 03             	sar    $0x3,%edx
f0101a71:	c1 e2 0c             	shl    $0xc,%edx
f0101a74:	39 d0                	cmp    %edx,%eax
f0101a76:	74 19                	je     f0101a91 <mem_init+0x9be>
f0101a78:	68 38 3f 10 f0       	push   $0xf0103f38
f0101a7d:	68 f8 43 10 f0       	push   $0xf01043f8
f0101a82:	68 e6 03 00 00       	push   $0x3e6
f0101a87:	68 b8 43 10 f0       	push   $0xf01043b8
f0101a8c:	e8 fa e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a91:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a96:	74 19                	je     f0101ab1 <mem_init+0x9de>
f0101a98:	68 c2 45 10 f0       	push   $0xf01045c2
f0101a9d:	68 f8 43 10 f0       	push   $0xf01043f8
f0101aa2:	68 e7 03 00 00       	push   $0x3e7
f0101aa7:	68 b8 43 10 f0       	push   $0xf01043b8
f0101aac:	e8 da e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101ab1:	83 ec 04             	sub    $0x4,%esp
f0101ab4:	6a 00                	push   $0x0
f0101ab6:	68 00 10 00 00       	push   $0x1000
f0101abb:	57                   	push   %edi
f0101abc:	e8 a7 f3 ff ff       	call   f0100e68 <pgdir_walk>
f0101ac1:	83 c4 10             	add    $0x10,%esp
f0101ac4:	f6 00 04             	testb  $0x4,(%eax)
f0101ac7:	75 19                	jne    f0101ae2 <mem_init+0xa0f>
f0101ac9:	68 e8 3f 10 f0       	push   $0xf0103fe8
f0101ace:	68 f8 43 10 f0       	push   $0xf01043f8
f0101ad3:	68 e8 03 00 00       	push   $0x3e8
f0101ad8:	68 b8 43 10 f0       	push   $0xf01043b8
f0101add:	e8 a9 e5 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101ae2:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f0101ae7:	f6 00 04             	testb  $0x4,(%eax)
f0101aea:	75 19                	jne    f0101b05 <mem_init+0xa32>
f0101aec:	68 d3 45 10 f0       	push   $0xf01045d3
f0101af1:	68 f8 43 10 f0       	push   $0xf01043f8
f0101af6:	68 e9 03 00 00       	push   $0x3e9
f0101afb:	68 b8 43 10 f0       	push   $0xf01043b8
f0101b00:	e8 86 e5 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b05:	6a 02                	push   $0x2
f0101b07:	68 00 10 00 00       	push   $0x1000
f0101b0c:	56                   	push   %esi
f0101b0d:	50                   	push   %eax
f0101b0e:	e8 36 f5 ff ff       	call   f0101049 <page_insert>
f0101b13:	83 c4 10             	add    $0x10,%esp
f0101b16:	85 c0                	test   %eax,%eax
f0101b18:	74 19                	je     f0101b33 <mem_init+0xa60>
f0101b1a:	68 fc 3e 10 f0       	push   $0xf0103efc
f0101b1f:	68 f8 43 10 f0       	push   $0xf01043f8
f0101b24:	68 ec 03 00 00       	push   $0x3ec
f0101b29:	68 b8 43 10 f0       	push   $0xf01043b8
f0101b2e:	e8 58 e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b33:	83 ec 04             	sub    $0x4,%esp
f0101b36:	6a 00                	push   $0x0
f0101b38:	68 00 10 00 00       	push   $0x1000
f0101b3d:	ff 35 4c 79 11 f0    	pushl  0xf011794c
f0101b43:	e8 20 f3 ff ff       	call   f0100e68 <pgdir_walk>
f0101b48:	83 c4 10             	add    $0x10,%esp
f0101b4b:	f6 00 02             	testb  $0x2,(%eax)
f0101b4e:	75 19                	jne    f0101b69 <mem_init+0xa96>
f0101b50:	68 1c 40 10 f0       	push   $0xf010401c
f0101b55:	68 f8 43 10 f0       	push   $0xf01043f8
f0101b5a:	68 ed 03 00 00       	push   $0x3ed
f0101b5f:	68 b8 43 10 f0       	push   $0xf01043b8
f0101b64:	e8 22 e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b69:	83 ec 04             	sub    $0x4,%esp
f0101b6c:	6a 00                	push   $0x0
f0101b6e:	68 00 10 00 00       	push   $0x1000
f0101b73:	ff 35 4c 79 11 f0    	pushl  0xf011794c
f0101b79:	e8 ea f2 ff ff       	call   f0100e68 <pgdir_walk>
f0101b7e:	83 c4 10             	add    $0x10,%esp
f0101b81:	f6 00 04             	testb  $0x4,(%eax)
f0101b84:	74 19                	je     f0101b9f <mem_init+0xacc>
f0101b86:	68 50 40 10 f0       	push   $0xf0104050
f0101b8b:	68 f8 43 10 f0       	push   $0xf01043f8
f0101b90:	68 ee 03 00 00       	push   $0x3ee
f0101b95:	68 b8 43 10 f0       	push   $0xf01043b8
f0101b9a:	e8 ec e4 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b9f:	6a 02                	push   $0x2
f0101ba1:	68 00 00 40 00       	push   $0x400000
f0101ba6:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101ba9:	ff 35 4c 79 11 f0    	pushl  0xf011794c
f0101baf:	e8 95 f4 ff ff       	call   f0101049 <page_insert>
f0101bb4:	83 c4 10             	add    $0x10,%esp
f0101bb7:	85 c0                	test   %eax,%eax
f0101bb9:	78 19                	js     f0101bd4 <mem_init+0xb01>
f0101bbb:	68 88 40 10 f0       	push   $0xf0104088
f0101bc0:	68 f8 43 10 f0       	push   $0xf01043f8
f0101bc5:	68 f1 03 00 00       	push   $0x3f1
f0101bca:	68 b8 43 10 f0       	push   $0xf01043b8
f0101bcf:	e8 b7 e4 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101bd4:	6a 02                	push   $0x2
f0101bd6:	68 00 10 00 00       	push   $0x1000
f0101bdb:	53                   	push   %ebx
f0101bdc:	ff 35 4c 79 11 f0    	pushl  0xf011794c
f0101be2:	e8 62 f4 ff ff       	call   f0101049 <page_insert>
f0101be7:	83 c4 10             	add    $0x10,%esp
f0101bea:	85 c0                	test   %eax,%eax
f0101bec:	74 19                	je     f0101c07 <mem_init+0xb34>
f0101bee:	68 c0 40 10 f0       	push   $0xf01040c0
f0101bf3:	68 f8 43 10 f0       	push   $0xf01043f8
f0101bf8:	68 f4 03 00 00       	push   $0x3f4
f0101bfd:	68 b8 43 10 f0       	push   $0xf01043b8
f0101c02:	e8 84 e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c07:	83 ec 04             	sub    $0x4,%esp
f0101c0a:	6a 00                	push   $0x0
f0101c0c:	68 00 10 00 00       	push   $0x1000
f0101c11:	ff 35 4c 79 11 f0    	pushl  0xf011794c
f0101c17:	e8 4c f2 ff ff       	call   f0100e68 <pgdir_walk>
f0101c1c:	83 c4 10             	add    $0x10,%esp
f0101c1f:	f6 00 04             	testb  $0x4,(%eax)
f0101c22:	74 19                	je     f0101c3d <mem_init+0xb6a>
f0101c24:	68 50 40 10 f0       	push   $0xf0104050
f0101c29:	68 f8 43 10 f0       	push   $0xf01043f8
f0101c2e:	68 f5 03 00 00       	push   $0x3f5
f0101c33:	68 b8 43 10 f0       	push   $0xf01043b8
f0101c38:	e8 4e e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c3d:	8b 3d 4c 79 11 f0    	mov    0xf011794c,%edi
f0101c43:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c48:	89 f8                	mov    %edi,%eax
f0101c4a:	e8 c6 ec ff ff       	call   f0100915 <check_va2pa>
f0101c4f:	89 c1                	mov    %eax,%ecx
f0101c51:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c54:	89 d8                	mov    %ebx,%eax
f0101c56:	2b 05 50 79 11 f0    	sub    0xf0117950,%eax
f0101c5c:	c1 f8 03             	sar    $0x3,%eax
f0101c5f:	c1 e0 0c             	shl    $0xc,%eax
f0101c62:	39 c1                	cmp    %eax,%ecx
f0101c64:	74 19                	je     f0101c7f <mem_init+0xbac>
f0101c66:	68 fc 40 10 f0       	push   $0xf01040fc
f0101c6b:	68 f8 43 10 f0       	push   $0xf01043f8
f0101c70:	68 f8 03 00 00       	push   $0x3f8
f0101c75:	68 b8 43 10 f0       	push   $0xf01043b8
f0101c7a:	e8 0c e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c7f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c84:	89 f8                	mov    %edi,%eax
f0101c86:	e8 8a ec ff ff       	call   f0100915 <check_va2pa>
f0101c8b:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c8e:	74 19                	je     f0101ca9 <mem_init+0xbd6>
f0101c90:	68 28 41 10 f0       	push   $0xf0104128
f0101c95:	68 f8 43 10 f0       	push   $0xf01043f8
f0101c9a:	68 f9 03 00 00       	push   $0x3f9
f0101c9f:	68 b8 43 10 f0       	push   $0xf01043b8
f0101ca4:	e8 e2 e3 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101ca9:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101cae:	74 19                	je     f0101cc9 <mem_init+0xbf6>
f0101cb0:	68 e9 45 10 f0       	push   $0xf01045e9
f0101cb5:	68 f8 43 10 f0       	push   $0xf01043f8
f0101cba:	68 fb 03 00 00       	push   $0x3fb
f0101cbf:	68 b8 43 10 f0       	push   $0xf01043b8
f0101cc4:	e8 c2 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101cc9:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101cce:	74 19                	je     f0101ce9 <mem_init+0xc16>
f0101cd0:	68 fa 45 10 f0       	push   $0xf01045fa
f0101cd5:	68 f8 43 10 f0       	push   $0xf01043f8
f0101cda:	68 fc 03 00 00       	push   $0x3fc
f0101cdf:	68 b8 43 10 f0       	push   $0xf01043b8
f0101ce4:	e8 a2 e3 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101ce9:	83 ec 0c             	sub    $0xc,%esp
f0101cec:	6a 00                	push   $0x0
f0101cee:	e8 a3 f0 ff ff       	call   f0100d96 <page_alloc>
f0101cf3:	83 c4 10             	add    $0x10,%esp
f0101cf6:	39 c6                	cmp    %eax,%esi
f0101cf8:	75 04                	jne    f0101cfe <mem_init+0xc2b>
f0101cfa:	85 c0                	test   %eax,%eax
f0101cfc:	75 19                	jne    f0101d17 <mem_init+0xc44>
f0101cfe:	68 58 41 10 f0       	push   $0xf0104158
f0101d03:	68 f8 43 10 f0       	push   $0xf01043f8
f0101d08:	68 ff 03 00 00       	push   $0x3ff
f0101d0d:	68 b8 43 10 f0       	push   $0xf01043b8
f0101d12:	e8 74 e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d17:	83 ec 08             	sub    $0x8,%esp
f0101d1a:	6a 00                	push   $0x0
f0101d1c:	ff 35 4c 79 11 f0    	pushl  0xf011794c
f0101d22:	e8 df f2 ff ff       	call   f0101006 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d27:	8b 3d 4c 79 11 f0    	mov    0xf011794c,%edi
f0101d2d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d32:	89 f8                	mov    %edi,%eax
f0101d34:	e8 dc eb ff ff       	call   f0100915 <check_va2pa>
f0101d39:	83 c4 10             	add    $0x10,%esp
f0101d3c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d3f:	74 19                	je     f0101d5a <mem_init+0xc87>
f0101d41:	68 7c 41 10 f0       	push   $0xf010417c
f0101d46:	68 f8 43 10 f0       	push   $0xf01043f8
f0101d4b:	68 03 04 00 00       	push   $0x403
f0101d50:	68 b8 43 10 f0       	push   $0xf01043b8
f0101d55:	e8 31 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d5a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d5f:	89 f8                	mov    %edi,%eax
f0101d61:	e8 af eb ff ff       	call   f0100915 <check_va2pa>
f0101d66:	89 da                	mov    %ebx,%edx
f0101d68:	2b 15 50 79 11 f0    	sub    0xf0117950,%edx
f0101d6e:	c1 fa 03             	sar    $0x3,%edx
f0101d71:	c1 e2 0c             	shl    $0xc,%edx
f0101d74:	39 d0                	cmp    %edx,%eax
f0101d76:	74 19                	je     f0101d91 <mem_init+0xcbe>
f0101d78:	68 28 41 10 f0       	push   $0xf0104128
f0101d7d:	68 f8 43 10 f0       	push   $0xf01043f8
f0101d82:	68 04 04 00 00       	push   $0x404
f0101d87:	68 b8 43 10 f0       	push   $0xf01043b8
f0101d8c:	e8 fa e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101d91:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d96:	74 19                	je     f0101db1 <mem_init+0xcde>
f0101d98:	68 a0 45 10 f0       	push   $0xf01045a0
f0101d9d:	68 f8 43 10 f0       	push   $0xf01043f8
f0101da2:	68 05 04 00 00       	push   $0x405
f0101da7:	68 b8 43 10 f0       	push   $0xf01043b8
f0101dac:	e8 da e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101db1:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101db6:	74 19                	je     f0101dd1 <mem_init+0xcfe>
f0101db8:	68 fa 45 10 f0       	push   $0xf01045fa
f0101dbd:	68 f8 43 10 f0       	push   $0xf01043f8
f0101dc2:	68 06 04 00 00       	push   $0x406
f0101dc7:	68 b8 43 10 f0       	push   $0xf01043b8
f0101dcc:	e8 ba e2 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101dd1:	6a 00                	push   $0x0
f0101dd3:	68 00 10 00 00       	push   $0x1000
f0101dd8:	53                   	push   %ebx
f0101dd9:	57                   	push   %edi
f0101dda:	e8 6a f2 ff ff       	call   f0101049 <page_insert>
f0101ddf:	83 c4 10             	add    $0x10,%esp
f0101de2:	85 c0                	test   %eax,%eax
f0101de4:	74 19                	je     f0101dff <mem_init+0xd2c>
f0101de6:	68 a0 41 10 f0       	push   $0xf01041a0
f0101deb:	68 f8 43 10 f0       	push   $0xf01043f8
f0101df0:	68 09 04 00 00       	push   $0x409
f0101df5:	68 b8 43 10 f0       	push   $0xf01043b8
f0101dfa:	e8 8c e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101dff:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e04:	75 19                	jne    f0101e1f <mem_init+0xd4c>
f0101e06:	68 0b 46 10 f0       	push   $0xf010460b
f0101e0b:	68 f8 43 10 f0       	push   $0xf01043f8
f0101e10:	68 0a 04 00 00       	push   $0x40a
f0101e15:	68 b8 43 10 f0       	push   $0xf01043b8
f0101e1a:	e8 6c e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101e1f:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101e22:	74 19                	je     f0101e3d <mem_init+0xd6a>
f0101e24:	68 17 46 10 f0       	push   $0xf0104617
f0101e29:	68 f8 43 10 f0       	push   $0xf01043f8
f0101e2e:	68 0b 04 00 00       	push   $0x40b
f0101e33:	68 b8 43 10 f0       	push   $0xf01043b8
f0101e38:	e8 4e e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e3d:	83 ec 08             	sub    $0x8,%esp
f0101e40:	68 00 10 00 00       	push   $0x1000
f0101e45:	ff 35 4c 79 11 f0    	pushl  0xf011794c
f0101e4b:	e8 b6 f1 ff ff       	call   f0101006 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e50:	8b 3d 4c 79 11 f0    	mov    0xf011794c,%edi
f0101e56:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e5b:	89 f8                	mov    %edi,%eax
f0101e5d:	e8 b3 ea ff ff       	call   f0100915 <check_va2pa>
f0101e62:	83 c4 10             	add    $0x10,%esp
f0101e65:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e68:	74 19                	je     f0101e83 <mem_init+0xdb0>
f0101e6a:	68 7c 41 10 f0       	push   $0xf010417c
f0101e6f:	68 f8 43 10 f0       	push   $0xf01043f8
f0101e74:	68 0f 04 00 00       	push   $0x40f
f0101e79:	68 b8 43 10 f0       	push   $0xf01043b8
f0101e7e:	e8 08 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e83:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e88:	89 f8                	mov    %edi,%eax
f0101e8a:	e8 86 ea ff ff       	call   f0100915 <check_va2pa>
f0101e8f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e92:	74 19                	je     f0101ead <mem_init+0xdda>
f0101e94:	68 d8 41 10 f0       	push   $0xf01041d8
f0101e99:	68 f8 43 10 f0       	push   $0xf01043f8
f0101e9e:	68 10 04 00 00       	push   $0x410
f0101ea3:	68 b8 43 10 f0       	push   $0xf01043b8
f0101ea8:	e8 de e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101ead:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101eb2:	74 19                	je     f0101ecd <mem_init+0xdfa>
f0101eb4:	68 2c 46 10 f0       	push   $0xf010462c
f0101eb9:	68 f8 43 10 f0       	push   $0xf01043f8
f0101ebe:	68 11 04 00 00       	push   $0x411
f0101ec3:	68 b8 43 10 f0       	push   $0xf01043b8
f0101ec8:	e8 be e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101ecd:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ed2:	74 19                	je     f0101eed <mem_init+0xe1a>
f0101ed4:	68 fa 45 10 f0       	push   $0xf01045fa
f0101ed9:	68 f8 43 10 f0       	push   $0xf01043f8
f0101ede:	68 12 04 00 00       	push   $0x412
f0101ee3:	68 b8 43 10 f0       	push   $0xf01043b8
f0101ee8:	e8 9e e1 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101eed:	83 ec 0c             	sub    $0xc,%esp
f0101ef0:	6a 00                	push   $0x0
f0101ef2:	e8 9f ee ff ff       	call   f0100d96 <page_alloc>
f0101ef7:	83 c4 10             	add    $0x10,%esp
f0101efa:	85 c0                	test   %eax,%eax
f0101efc:	74 04                	je     f0101f02 <mem_init+0xe2f>
f0101efe:	39 c3                	cmp    %eax,%ebx
f0101f00:	74 19                	je     f0101f1b <mem_init+0xe48>
f0101f02:	68 00 42 10 f0       	push   $0xf0104200
f0101f07:	68 f8 43 10 f0       	push   $0xf01043f8
f0101f0c:	68 15 04 00 00       	push   $0x415
f0101f11:	68 b8 43 10 f0       	push   $0xf01043b8
f0101f16:	e8 70 e1 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f1b:	83 ec 0c             	sub    $0xc,%esp
f0101f1e:	6a 00                	push   $0x0
f0101f20:	e8 71 ee ff ff       	call   f0100d96 <page_alloc>
f0101f25:	83 c4 10             	add    $0x10,%esp
f0101f28:	85 c0                	test   %eax,%eax
f0101f2a:	74 19                	je     f0101f45 <mem_init+0xe72>
f0101f2c:	68 4e 45 10 f0       	push   $0xf010454e
f0101f31:	68 f8 43 10 f0       	push   $0xf01043f8
f0101f36:	68 18 04 00 00       	push   $0x418
f0101f3b:	68 b8 43 10 f0       	push   $0xf01043b8
f0101f40:	e8 46 e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f45:	8b 0d 4c 79 11 f0    	mov    0xf011794c,%ecx
f0101f4b:	8b 11                	mov    (%ecx),%edx
f0101f4d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f53:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f56:	2b 05 50 79 11 f0    	sub    0xf0117950,%eax
f0101f5c:	c1 f8 03             	sar    $0x3,%eax
f0101f5f:	c1 e0 0c             	shl    $0xc,%eax
f0101f62:	39 c2                	cmp    %eax,%edx
f0101f64:	74 19                	je     f0101f7f <mem_init+0xeac>
f0101f66:	68 a4 3e 10 f0       	push   $0xf0103ea4
f0101f6b:	68 f8 43 10 f0       	push   $0xf01043f8
f0101f70:	68 1b 04 00 00       	push   $0x41b
f0101f75:	68 b8 43 10 f0       	push   $0xf01043b8
f0101f7a:	e8 0c e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101f7f:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f85:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f88:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f8d:	74 19                	je     f0101fa8 <mem_init+0xed5>
f0101f8f:	68 b1 45 10 f0       	push   $0xf01045b1
f0101f94:	68 f8 43 10 f0       	push   $0xf01043f8
f0101f99:	68 1d 04 00 00       	push   $0x41d
f0101f9e:	68 b8 43 10 f0       	push   $0xf01043b8
f0101fa3:	e8 e3 e0 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101fa8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fab:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101fb1:	83 ec 0c             	sub    $0xc,%esp
f0101fb4:	50                   	push   %eax
f0101fb5:	e8 4c ee ff ff       	call   f0100e06 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101fba:	83 c4 0c             	add    $0xc,%esp
f0101fbd:	6a 01                	push   $0x1
f0101fbf:	68 00 10 40 00       	push   $0x401000
f0101fc4:	ff 35 4c 79 11 f0    	pushl  0xf011794c
f0101fca:	e8 99 ee ff ff       	call   f0100e68 <pgdir_walk>
f0101fcf:	89 c7                	mov    %eax,%edi
f0101fd1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fd4:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f0101fd9:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fdc:	8b 40 04             	mov    0x4(%eax),%eax
f0101fdf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fe4:	8b 0d 48 79 11 f0    	mov    0xf0117948,%ecx
f0101fea:	89 c2                	mov    %eax,%edx
f0101fec:	c1 ea 0c             	shr    $0xc,%edx
f0101fef:	83 c4 10             	add    $0x10,%esp
f0101ff2:	39 ca                	cmp    %ecx,%edx
f0101ff4:	72 15                	jb     f010200b <mem_init+0xf38>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ff6:	50                   	push   %eax
f0101ff7:	68 e4 3b 10 f0       	push   $0xf0103be4
f0101ffc:	68 24 04 00 00       	push   $0x424
f0102001:	68 b8 43 10 f0       	push   $0xf01043b8
f0102006:	e8 80 e0 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f010200b:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102010:	39 c7                	cmp    %eax,%edi
f0102012:	74 19                	je     f010202d <mem_init+0xf5a>
f0102014:	68 3d 46 10 f0       	push   $0xf010463d
f0102019:	68 f8 43 10 f0       	push   $0xf01043f8
f010201e:	68 25 04 00 00       	push   $0x425
f0102023:	68 b8 43 10 f0       	push   $0xf01043b8
f0102028:	e8 5e e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f010202d:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102030:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102037:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010203a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102040:	2b 05 50 79 11 f0    	sub    0xf0117950,%eax
f0102046:	c1 f8 03             	sar    $0x3,%eax
f0102049:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010204c:	89 c2                	mov    %eax,%edx
f010204e:	c1 ea 0c             	shr    $0xc,%edx
f0102051:	39 d1                	cmp    %edx,%ecx
f0102053:	77 12                	ja     f0102067 <mem_init+0xf94>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102055:	50                   	push   %eax
f0102056:	68 e4 3b 10 f0       	push   $0xf0103be4
f010205b:	6a 52                	push   $0x52
f010205d:	68 de 43 10 f0       	push   $0xf01043de
f0102062:	e8 24 e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102067:	83 ec 04             	sub    $0x4,%esp
f010206a:	68 00 10 00 00       	push   $0x1000
f010206f:	68 ff 00 00 00       	push   $0xff
f0102074:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102079:	50                   	push   %eax
f010207a:	e8 c7 11 00 00       	call   f0103246 <memset>
	page_free(pp0);
f010207f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102082:	89 3c 24             	mov    %edi,(%esp)
f0102085:	e8 7c ed ff ff       	call   f0100e06 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010208a:	83 c4 0c             	add    $0xc,%esp
f010208d:	6a 01                	push   $0x1
f010208f:	6a 00                	push   $0x0
f0102091:	ff 35 4c 79 11 f0    	pushl  0xf011794c
f0102097:	e8 cc ed ff ff       	call   f0100e68 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010209c:	89 fa                	mov    %edi,%edx
f010209e:	2b 15 50 79 11 f0    	sub    0xf0117950,%edx
f01020a4:	c1 fa 03             	sar    $0x3,%edx
f01020a7:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020aa:	89 d0                	mov    %edx,%eax
f01020ac:	c1 e8 0c             	shr    $0xc,%eax
f01020af:	83 c4 10             	add    $0x10,%esp
f01020b2:	3b 05 48 79 11 f0    	cmp    0xf0117948,%eax
f01020b8:	72 12                	jb     f01020cc <mem_init+0xff9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020ba:	52                   	push   %edx
f01020bb:	68 e4 3b 10 f0       	push   $0xf0103be4
f01020c0:	6a 52                	push   $0x52
f01020c2:	68 de 43 10 f0       	push   $0xf01043de
f01020c7:	e8 bf df ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f01020cc:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01020d2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020d5:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020db:	f6 00 01             	testb  $0x1,(%eax)
f01020de:	74 19                	je     f01020f9 <mem_init+0x1026>
f01020e0:	68 55 46 10 f0       	push   $0xf0104655
f01020e5:	68 f8 43 10 f0       	push   $0xf01043f8
f01020ea:	68 2f 04 00 00       	push   $0x42f
f01020ef:	68 b8 43 10 f0       	push   $0xf01043b8
f01020f4:	e8 92 df ff ff       	call   f010008b <_panic>
f01020f9:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020fc:	39 d0                	cmp    %edx,%eax
f01020fe:	75 db                	jne    f01020db <mem_init+0x1008>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102100:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f0102105:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010210b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010210e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102114:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102117:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f010211d:	83 ec 0c             	sub    $0xc,%esp
f0102120:	50                   	push   %eax
f0102121:	e8 e0 ec ff ff       	call   f0100e06 <page_free>
	page_free(pp1);
f0102126:	89 1c 24             	mov    %ebx,(%esp)
f0102129:	e8 d8 ec ff ff       	call   f0100e06 <page_free>
	page_free(pp2);
f010212e:	89 34 24             	mov    %esi,(%esp)
f0102131:	e8 d0 ec ff ff       	call   f0100e06 <page_free>

	cprintf("check_page() succeeded!\n");
f0102136:	c7 04 24 6c 46 10 f0 	movl   $0xf010466c,(%esp)
f010213d:	e8 4b 06 00 00       	call   f010278d <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	 
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), (PTE_U | PTE_P));	
f0102142:	a1 50 79 11 f0       	mov    0xf0117950,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102147:	83 c4 10             	add    $0x10,%esp
f010214a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010214f:	77 15                	ja     f0102166 <mem_init+0x1093>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102151:	50                   	push   %eax
f0102152:	68 08 3c 10 f0       	push   $0xf0103c08
f0102157:	68 f3 00 00 00       	push   $0xf3
f010215c:	68 b8 43 10 f0       	push   $0xf01043b8
f0102161:	e8 25 df ff ff       	call   f010008b <_panic>
f0102166:	83 ec 08             	sub    $0x8,%esp
f0102169:	6a 05                	push   $0x5
f010216b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102170:	50                   	push   %eax
f0102171:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102176:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010217b:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f0102180:	e8 b0 ed ff ff       	call   f0100f35 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102185:	83 c4 10             	add    $0x10,%esp
f0102188:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f010218d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102192:	77 15                	ja     f01021a9 <mem_init+0x10d6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102194:	50                   	push   %eax
f0102195:	68 08 3c 10 f0       	push   $0xf0103c08
f010219a:	68 01 01 00 00       	push   $0x101
f010219f:	68 b8 43 10 f0       	push   $0xf01043b8
f01021a4:	e8 e2 de ff ff       	call   f010008b <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	
 	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01021a9:	83 ec 08             	sub    $0x8,%esp
f01021ac:	6a 02                	push   $0x2
f01021ae:	68 00 d0 10 00       	push   $0x10d000
f01021b3:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021b8:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01021bd:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f01021c2:	e8 6e ed ff ff       	call   f0100f35 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE/* ~KERNBASE + 1 */, 0, PTE_W);
f01021c7:	83 c4 08             	add    $0x8,%esp
f01021ca:	6a 02                	push   $0x2
f01021cc:	6a 00                	push   $0x0
f01021ce:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01021d3:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021d8:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f01021dd:	e8 53 ed ff ff       	call   f0100f35 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01021e2:	8b 35 4c 79 11 f0    	mov    0xf011794c,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021e8:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01021ed:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021f0:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021f7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021fc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021ff:	8b 3d 50 79 11 f0    	mov    0xf0117950,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102205:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102208:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010220b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102210:	eb 55                	jmp    f0102267 <mem_init+0x1194>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102212:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102218:	89 f0                	mov    %esi,%eax
f010221a:	e8 f6 e6 ff ff       	call   f0100915 <check_va2pa>
f010221f:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102226:	77 15                	ja     f010223d <mem_init+0x116a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102228:	57                   	push   %edi
f0102229:	68 08 3c 10 f0       	push   $0xf0103c08
f010222e:	68 71 03 00 00       	push   $0x371
f0102233:	68 b8 43 10 f0       	push   $0xf01043b8
f0102238:	e8 4e de ff ff       	call   f010008b <_panic>
f010223d:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f0102244:	39 c2                	cmp    %eax,%edx
f0102246:	74 19                	je     f0102261 <mem_init+0x118e>
f0102248:	68 24 42 10 f0       	push   $0xf0104224
f010224d:	68 f8 43 10 f0       	push   $0xf01043f8
f0102252:	68 71 03 00 00       	push   $0x371
f0102257:	68 b8 43 10 f0       	push   $0xf01043b8
f010225c:	e8 2a de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102261:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102267:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010226a:	77 a6                	ja     f0102212 <mem_init+0x113f>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010226c:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010226f:	c1 e7 0c             	shl    $0xc,%edi
f0102272:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102277:	eb 30                	jmp    f01022a9 <mem_init+0x11d6>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102279:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f010227f:	89 f0                	mov    %esi,%eax
f0102281:	e8 8f e6 ff ff       	call   f0100915 <check_va2pa>
f0102286:	39 c3                	cmp    %eax,%ebx
f0102288:	74 19                	je     f01022a3 <mem_init+0x11d0>
f010228a:	68 58 42 10 f0       	push   $0xf0104258
f010228f:	68 f8 43 10 f0       	push   $0xf01043f8
f0102294:	68 76 03 00 00       	push   $0x376
f0102299:	68 b8 43 10 f0       	push   $0xf01043b8
f010229e:	e8 e8 dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01022a3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01022a9:	39 fb                	cmp    %edi,%ebx
f01022ab:	72 cc                	jb     f0102279 <mem_init+0x11a6>
f01022ad:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01022b2:	89 da                	mov    %ebx,%edx
f01022b4:	89 f0                	mov    %esi,%eax
f01022b6:	e8 5a e6 ff ff       	call   f0100915 <check_va2pa>
f01022bb:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f01022c1:	39 c2                	cmp    %eax,%edx
f01022c3:	74 19                	je     f01022de <mem_init+0x120b>
f01022c5:	68 80 42 10 f0       	push   $0xf0104280
f01022ca:	68 f8 43 10 f0       	push   $0xf01043f8
f01022cf:	68 7a 03 00 00       	push   $0x37a
f01022d4:	68 b8 43 10 f0       	push   $0xf01043b8
f01022d9:	e8 ad dd ff ff       	call   f010008b <_panic>
f01022de:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01022e4:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01022ea:	75 c6                	jne    f01022b2 <mem_init+0x11df>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022ec:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01022f1:	89 f0                	mov    %esi,%eax
f01022f3:	e8 1d e6 ff ff       	call   f0100915 <check_va2pa>
f01022f8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022fb:	74 51                	je     f010234e <mem_init+0x127b>
f01022fd:	68 c8 42 10 f0       	push   $0xf01042c8
f0102302:	68 f8 43 10 f0       	push   $0xf01043f8
f0102307:	68 7b 03 00 00       	push   $0x37b
f010230c:	68 b8 43 10 f0       	push   $0xf01043b8
f0102311:	e8 75 dd ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102316:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f010231b:	72 36                	jb     f0102353 <mem_init+0x1280>
f010231d:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102322:	76 07                	jbe    f010232b <mem_init+0x1258>
f0102324:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102329:	75 28                	jne    f0102353 <mem_init+0x1280>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f010232b:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f010232f:	0f 85 83 00 00 00    	jne    f01023b8 <mem_init+0x12e5>
f0102335:	68 85 46 10 f0       	push   $0xf0104685
f010233a:	68 f8 43 10 f0       	push   $0xf01043f8
f010233f:	68 83 03 00 00       	push   $0x383
f0102344:	68 b8 43 10 f0       	push   $0xf01043b8
f0102349:	e8 3d dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010234e:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102353:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102358:	76 3f                	jbe    f0102399 <mem_init+0x12c6>
				assert(pgdir[i] & PTE_P);
f010235a:	8b 14 86             	mov    (%esi,%eax,4),%edx
f010235d:	f6 c2 01             	test   $0x1,%dl
f0102360:	75 19                	jne    f010237b <mem_init+0x12a8>
f0102362:	68 85 46 10 f0       	push   $0xf0104685
f0102367:	68 f8 43 10 f0       	push   $0xf01043f8
f010236c:	68 87 03 00 00       	push   $0x387
f0102371:	68 b8 43 10 f0       	push   $0xf01043b8
f0102376:	e8 10 dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f010237b:	f6 c2 02             	test   $0x2,%dl
f010237e:	75 38                	jne    f01023b8 <mem_init+0x12e5>
f0102380:	68 96 46 10 f0       	push   $0xf0104696
f0102385:	68 f8 43 10 f0       	push   $0xf01043f8
f010238a:	68 88 03 00 00       	push   $0x388
f010238f:	68 b8 43 10 f0       	push   $0xf01043b8
f0102394:	e8 f2 dc ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102399:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f010239d:	74 19                	je     f01023b8 <mem_init+0x12e5>
f010239f:	68 a7 46 10 f0       	push   $0xf01046a7
f01023a4:	68 f8 43 10 f0       	push   $0xf01043f8
f01023a9:	68 8a 03 00 00       	push   $0x38a
f01023ae:	68 b8 43 10 f0       	push   $0xf01043b8
f01023b3:	e8 d3 dc ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01023b8:	83 c0 01             	add    $0x1,%eax
f01023bb:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01023c0:	0f 86 50 ff ff ff    	jbe    f0102316 <mem_init+0x1243>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01023c6:	83 ec 0c             	sub    $0xc,%esp
f01023c9:	68 f8 42 10 f0       	push   $0xf01042f8
f01023ce:	e8 ba 03 00 00       	call   f010278d <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01023d3:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023d8:	83 c4 10             	add    $0x10,%esp
f01023db:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023e0:	77 15                	ja     f01023f7 <mem_init+0x1324>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023e2:	50                   	push   %eax
f01023e3:	68 08 3c 10 f0       	push   $0xf0103c08
f01023e8:	68 18 01 00 00       	push   $0x118
f01023ed:	68 b8 43 10 f0       	push   $0xf01043b8
f01023f2:	e8 94 dc ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01023f7:	05 00 00 00 10       	add    $0x10000000,%eax
f01023fc:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01023ff:	b8 00 00 00 00       	mov    $0x0,%eax
f0102404:	e8 ff e5 ff ff       	call   f0100a08 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102409:	0f 20 c0             	mov    %cr0,%eax
f010240c:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f010240f:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102414:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102417:	83 ec 0c             	sub    $0xc,%esp
f010241a:	6a 00                	push   $0x0
f010241c:	e8 75 e9 ff ff       	call   f0100d96 <page_alloc>
f0102421:	89 c3                	mov    %eax,%ebx
f0102423:	83 c4 10             	add    $0x10,%esp
f0102426:	85 c0                	test   %eax,%eax
f0102428:	75 19                	jne    f0102443 <mem_init+0x1370>
f010242a:	68 a3 44 10 f0       	push   $0xf01044a3
f010242f:	68 f8 43 10 f0       	push   $0xf01043f8
f0102434:	68 4a 04 00 00       	push   $0x44a
f0102439:	68 b8 43 10 f0       	push   $0xf01043b8
f010243e:	e8 48 dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0102443:	83 ec 0c             	sub    $0xc,%esp
f0102446:	6a 00                	push   $0x0
f0102448:	e8 49 e9 ff ff       	call   f0100d96 <page_alloc>
f010244d:	89 c7                	mov    %eax,%edi
f010244f:	83 c4 10             	add    $0x10,%esp
f0102452:	85 c0                	test   %eax,%eax
f0102454:	75 19                	jne    f010246f <mem_init+0x139c>
f0102456:	68 b9 44 10 f0       	push   $0xf01044b9
f010245b:	68 f8 43 10 f0       	push   $0xf01043f8
f0102460:	68 4b 04 00 00       	push   $0x44b
f0102465:	68 b8 43 10 f0       	push   $0xf01043b8
f010246a:	e8 1c dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010246f:	83 ec 0c             	sub    $0xc,%esp
f0102472:	6a 00                	push   $0x0
f0102474:	e8 1d e9 ff ff       	call   f0100d96 <page_alloc>
f0102479:	89 c6                	mov    %eax,%esi
f010247b:	83 c4 10             	add    $0x10,%esp
f010247e:	85 c0                	test   %eax,%eax
f0102480:	75 19                	jne    f010249b <mem_init+0x13c8>
f0102482:	68 cf 44 10 f0       	push   $0xf01044cf
f0102487:	68 f8 43 10 f0       	push   $0xf01043f8
f010248c:	68 4c 04 00 00       	push   $0x44c
f0102491:	68 b8 43 10 f0       	push   $0xf01043b8
f0102496:	e8 f0 db ff ff       	call   f010008b <_panic>
	page_free(pp0);
f010249b:	83 ec 0c             	sub    $0xc,%esp
f010249e:	53                   	push   %ebx
f010249f:	e8 62 e9 ff ff       	call   f0100e06 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024a4:	89 f8                	mov    %edi,%eax
f01024a6:	2b 05 50 79 11 f0    	sub    0xf0117950,%eax
f01024ac:	c1 f8 03             	sar    $0x3,%eax
f01024af:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024b2:	89 c2                	mov    %eax,%edx
f01024b4:	c1 ea 0c             	shr    $0xc,%edx
f01024b7:	83 c4 10             	add    $0x10,%esp
f01024ba:	3b 15 48 79 11 f0    	cmp    0xf0117948,%edx
f01024c0:	72 12                	jb     f01024d4 <mem_init+0x1401>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024c2:	50                   	push   %eax
f01024c3:	68 e4 3b 10 f0       	push   $0xf0103be4
f01024c8:	6a 52                	push   $0x52
f01024ca:	68 de 43 10 f0       	push   $0xf01043de
f01024cf:	e8 b7 db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01024d4:	83 ec 04             	sub    $0x4,%esp
f01024d7:	68 00 10 00 00       	push   $0x1000
f01024dc:	6a 01                	push   $0x1
f01024de:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024e3:	50                   	push   %eax
f01024e4:	e8 5d 0d 00 00       	call   f0103246 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024e9:	89 f0                	mov    %esi,%eax
f01024eb:	2b 05 50 79 11 f0    	sub    0xf0117950,%eax
f01024f1:	c1 f8 03             	sar    $0x3,%eax
f01024f4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024f7:	89 c2                	mov    %eax,%edx
f01024f9:	c1 ea 0c             	shr    $0xc,%edx
f01024fc:	83 c4 10             	add    $0x10,%esp
f01024ff:	3b 15 48 79 11 f0    	cmp    0xf0117948,%edx
f0102505:	72 12                	jb     f0102519 <mem_init+0x1446>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102507:	50                   	push   %eax
f0102508:	68 e4 3b 10 f0       	push   $0xf0103be4
f010250d:	6a 52                	push   $0x52
f010250f:	68 de 43 10 f0       	push   $0xf01043de
f0102514:	e8 72 db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102519:	83 ec 04             	sub    $0x4,%esp
f010251c:	68 00 10 00 00       	push   $0x1000
f0102521:	6a 02                	push   $0x2
f0102523:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102528:	50                   	push   %eax
f0102529:	e8 18 0d 00 00       	call   f0103246 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010252e:	6a 02                	push   $0x2
f0102530:	68 00 10 00 00       	push   $0x1000
f0102535:	57                   	push   %edi
f0102536:	ff 35 4c 79 11 f0    	pushl  0xf011794c
f010253c:	e8 08 eb ff ff       	call   f0101049 <page_insert>
	assert(pp1->pp_ref == 1);
f0102541:	83 c4 20             	add    $0x20,%esp
f0102544:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102549:	74 19                	je     f0102564 <mem_init+0x1491>
f010254b:	68 a0 45 10 f0       	push   $0xf01045a0
f0102550:	68 f8 43 10 f0       	push   $0xf01043f8
f0102555:	68 51 04 00 00       	push   $0x451
f010255a:	68 b8 43 10 f0       	push   $0xf01043b8
f010255f:	e8 27 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102564:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010256b:	01 01 01 
f010256e:	74 19                	je     f0102589 <mem_init+0x14b6>
f0102570:	68 18 43 10 f0       	push   $0xf0104318
f0102575:	68 f8 43 10 f0       	push   $0xf01043f8
f010257a:	68 52 04 00 00       	push   $0x452
f010257f:	68 b8 43 10 f0       	push   $0xf01043b8
f0102584:	e8 02 db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102589:	6a 02                	push   $0x2
f010258b:	68 00 10 00 00       	push   $0x1000
f0102590:	56                   	push   %esi
f0102591:	ff 35 4c 79 11 f0    	pushl  0xf011794c
f0102597:	e8 ad ea ff ff       	call   f0101049 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010259c:	83 c4 10             	add    $0x10,%esp
f010259f:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01025a6:	02 02 02 
f01025a9:	74 19                	je     f01025c4 <mem_init+0x14f1>
f01025ab:	68 3c 43 10 f0       	push   $0xf010433c
f01025b0:	68 f8 43 10 f0       	push   $0xf01043f8
f01025b5:	68 54 04 00 00       	push   $0x454
f01025ba:	68 b8 43 10 f0       	push   $0xf01043b8
f01025bf:	e8 c7 da ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01025c4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01025c9:	74 19                	je     f01025e4 <mem_init+0x1511>
f01025cb:	68 c2 45 10 f0       	push   $0xf01045c2
f01025d0:	68 f8 43 10 f0       	push   $0xf01043f8
f01025d5:	68 55 04 00 00       	push   $0x455
f01025da:	68 b8 43 10 f0       	push   $0xf01043b8
f01025df:	e8 a7 da ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01025e4:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01025e9:	74 19                	je     f0102604 <mem_init+0x1531>
f01025eb:	68 2c 46 10 f0       	push   $0xf010462c
f01025f0:	68 f8 43 10 f0       	push   $0xf01043f8
f01025f5:	68 56 04 00 00       	push   $0x456
f01025fa:	68 b8 43 10 f0       	push   $0xf01043b8
f01025ff:	e8 87 da ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102604:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010260b:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010260e:	89 f0                	mov    %esi,%eax
f0102610:	2b 05 50 79 11 f0    	sub    0xf0117950,%eax
f0102616:	c1 f8 03             	sar    $0x3,%eax
f0102619:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010261c:	89 c2                	mov    %eax,%edx
f010261e:	c1 ea 0c             	shr    $0xc,%edx
f0102621:	3b 15 48 79 11 f0    	cmp    0xf0117948,%edx
f0102627:	72 12                	jb     f010263b <mem_init+0x1568>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102629:	50                   	push   %eax
f010262a:	68 e4 3b 10 f0       	push   $0xf0103be4
f010262f:	6a 52                	push   $0x52
f0102631:	68 de 43 10 f0       	push   $0xf01043de
f0102636:	e8 50 da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010263b:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102642:	03 03 03 
f0102645:	74 19                	je     f0102660 <mem_init+0x158d>
f0102647:	68 60 43 10 f0       	push   $0xf0104360
f010264c:	68 f8 43 10 f0       	push   $0xf01043f8
f0102651:	68 58 04 00 00       	push   $0x458
f0102656:	68 b8 43 10 f0       	push   $0xf01043b8
f010265b:	e8 2b da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102660:	83 ec 08             	sub    $0x8,%esp
f0102663:	68 00 10 00 00       	push   $0x1000
f0102668:	ff 35 4c 79 11 f0    	pushl  0xf011794c
f010266e:	e8 93 e9 ff ff       	call   f0101006 <page_remove>
	assert(pp2->pp_ref == 0);
f0102673:	83 c4 10             	add    $0x10,%esp
f0102676:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010267b:	74 19                	je     f0102696 <mem_init+0x15c3>
f010267d:	68 fa 45 10 f0       	push   $0xf01045fa
f0102682:	68 f8 43 10 f0       	push   $0xf01043f8
f0102687:	68 5a 04 00 00       	push   $0x45a
f010268c:	68 b8 43 10 f0       	push   $0xf01043b8
f0102691:	e8 f5 d9 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102696:	8b 0d 4c 79 11 f0    	mov    0xf011794c,%ecx
f010269c:	8b 11                	mov    (%ecx),%edx
f010269e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01026a4:	89 d8                	mov    %ebx,%eax
f01026a6:	2b 05 50 79 11 f0    	sub    0xf0117950,%eax
f01026ac:	c1 f8 03             	sar    $0x3,%eax
f01026af:	c1 e0 0c             	shl    $0xc,%eax
f01026b2:	39 c2                	cmp    %eax,%edx
f01026b4:	74 19                	je     f01026cf <mem_init+0x15fc>
f01026b6:	68 a4 3e 10 f0       	push   $0xf0103ea4
f01026bb:	68 f8 43 10 f0       	push   $0xf01043f8
f01026c0:	68 5d 04 00 00       	push   $0x45d
f01026c5:	68 b8 43 10 f0       	push   $0xf01043b8
f01026ca:	e8 bc d9 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01026cf:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01026d5:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026da:	74 19                	je     f01026f5 <mem_init+0x1622>
f01026dc:	68 b1 45 10 f0       	push   $0xf01045b1
f01026e1:	68 f8 43 10 f0       	push   $0xf01043f8
f01026e6:	68 5f 04 00 00       	push   $0x45f
f01026eb:	68 b8 43 10 f0       	push   $0xf01043b8
f01026f0:	e8 96 d9 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01026f5:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01026fb:	83 ec 0c             	sub    $0xc,%esp
f01026fe:	53                   	push   %ebx
f01026ff:	e8 02 e7 ff ff       	call   f0100e06 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102704:	c7 04 24 8c 43 10 f0 	movl   $0xf010438c,(%esp)
f010270b:	e8 7d 00 00 00       	call   f010278d <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102710:	83 c4 10             	add    $0x10,%esp
f0102713:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102716:	5b                   	pop    %ebx
f0102717:	5e                   	pop    %esi
f0102718:	5f                   	pop    %edi
f0102719:	5d                   	pop    %ebp
f010271a:	c3                   	ret    

f010271b <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010271b:	55                   	push   %ebp
f010271c:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010271e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102721:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102724:	5d                   	pop    %ebp
f0102725:	c3                   	ret    

f0102726 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102726:	55                   	push   %ebp
f0102727:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102729:	ba 70 00 00 00       	mov    $0x70,%edx
f010272e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102731:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102732:	ba 71 00 00 00       	mov    $0x71,%edx
f0102737:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102738:	0f b6 c0             	movzbl %al,%eax
}
f010273b:	5d                   	pop    %ebp
f010273c:	c3                   	ret    

f010273d <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010273d:	55                   	push   %ebp
f010273e:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102740:	ba 70 00 00 00       	mov    $0x70,%edx
f0102745:	8b 45 08             	mov    0x8(%ebp),%eax
f0102748:	ee                   	out    %al,(%dx)
f0102749:	ba 71 00 00 00       	mov    $0x71,%edx
f010274e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102751:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102752:	5d                   	pop    %ebp
f0102753:	c3                   	ret    

f0102754 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102754:	55                   	push   %ebp
f0102755:	89 e5                	mov    %esp,%ebp
f0102757:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010275a:	ff 75 08             	pushl  0x8(%ebp)
f010275d:	e8 9e de ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f0102762:	83 c4 10             	add    $0x10,%esp
f0102765:	c9                   	leave  
f0102766:	c3                   	ret    

f0102767 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102767:	55                   	push   %ebp
f0102768:	89 e5                	mov    %esp,%ebp
f010276a:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010276d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102774:	ff 75 0c             	pushl  0xc(%ebp)
f0102777:	ff 75 08             	pushl  0x8(%ebp)
f010277a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010277d:	50                   	push   %eax
f010277e:	68 54 27 10 f0       	push   $0xf0102754
f0102783:	e8 52 04 00 00       	call   f0102bda <vprintfmt>
	return cnt;
}
f0102788:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010278b:	c9                   	leave  
f010278c:	c3                   	ret    

f010278d <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010278d:	55                   	push   %ebp
f010278e:	89 e5                	mov    %esp,%ebp
f0102790:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102793:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102796:	50                   	push   %eax
f0102797:	ff 75 08             	pushl  0x8(%ebp)
f010279a:	e8 c8 ff ff ff       	call   f0102767 <vcprintf>
	va_end(ap);

	return cnt;
}
f010279f:	c9                   	leave  
f01027a0:	c3                   	ret    

f01027a1 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01027a1:	55                   	push   %ebp
f01027a2:	89 e5                	mov    %esp,%ebp
f01027a4:	57                   	push   %edi
f01027a5:	56                   	push   %esi
f01027a6:	53                   	push   %ebx
f01027a7:	83 ec 14             	sub    $0x14,%esp
f01027aa:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01027ad:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01027b0:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01027b3:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01027b6:	8b 1a                	mov    (%edx),%ebx
f01027b8:	8b 01                	mov    (%ecx),%eax
f01027ba:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01027bd:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01027c4:	eb 7f                	jmp    f0102845 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01027c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01027c9:	01 d8                	add    %ebx,%eax
f01027cb:	89 c6                	mov    %eax,%esi
f01027cd:	c1 ee 1f             	shr    $0x1f,%esi
f01027d0:	01 c6                	add    %eax,%esi
f01027d2:	d1 fe                	sar    %esi
f01027d4:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01027d7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027da:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01027dd:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027df:	eb 03                	jmp    f01027e4 <stab_binsearch+0x43>
			m--;
f01027e1:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027e4:	39 c3                	cmp    %eax,%ebx
f01027e6:	7f 0d                	jg     f01027f5 <stab_binsearch+0x54>
f01027e8:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01027ec:	83 ea 0c             	sub    $0xc,%edx
f01027ef:	39 f9                	cmp    %edi,%ecx
f01027f1:	75 ee                	jne    f01027e1 <stab_binsearch+0x40>
f01027f3:	eb 05                	jmp    f01027fa <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01027f5:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01027f8:	eb 4b                	jmp    f0102845 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01027fa:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027fd:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102800:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102804:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102807:	76 11                	jbe    f010281a <stab_binsearch+0x79>
			*region_left = m;
f0102809:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010280c:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010280e:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102811:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102818:	eb 2b                	jmp    f0102845 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010281a:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010281d:	73 14                	jae    f0102833 <stab_binsearch+0x92>
			*region_right = m - 1;
f010281f:	83 e8 01             	sub    $0x1,%eax
f0102822:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102825:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102828:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010282a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102831:	eb 12                	jmp    f0102845 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102833:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102836:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102838:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010283c:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010283e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102845:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102848:	0f 8e 78 ff ff ff    	jle    f01027c6 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010284e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0102852:	75 0f                	jne    f0102863 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0102854:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102857:	8b 00                	mov    (%eax),%eax
f0102859:	83 e8 01             	sub    $0x1,%eax
f010285c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010285f:	89 06                	mov    %eax,(%esi)
f0102861:	eb 2c                	jmp    f010288f <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102863:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102866:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102868:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010286b:	8b 0e                	mov    (%esi),%ecx
f010286d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102870:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102873:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102876:	eb 03                	jmp    f010287b <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102878:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010287b:	39 c8                	cmp    %ecx,%eax
f010287d:	7e 0b                	jle    f010288a <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010287f:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0102883:	83 ea 0c             	sub    $0xc,%edx
f0102886:	39 df                	cmp    %ebx,%edi
f0102888:	75 ee                	jne    f0102878 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010288a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010288d:	89 06                	mov    %eax,(%esi)
	}
}
f010288f:	83 c4 14             	add    $0x14,%esp
f0102892:	5b                   	pop    %ebx
f0102893:	5e                   	pop    %esi
f0102894:	5f                   	pop    %edi
f0102895:	5d                   	pop    %ebp
f0102896:	c3                   	ret    

f0102897 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102897:	55                   	push   %ebp
f0102898:	89 e5                	mov    %esp,%ebp
f010289a:	57                   	push   %edi
f010289b:	56                   	push   %esi
f010289c:	53                   	push   %ebx
f010289d:	83 ec 3c             	sub    $0x3c,%esp
f01028a0:	8b 75 08             	mov    0x8(%ebp),%esi
f01028a3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01028a6:	c7 03 b5 46 10 f0    	movl   $0xf01046b5,(%ebx)
	info->eip_line = 0;
f01028ac:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01028b3:	c7 43 08 b5 46 10 f0 	movl   $0xf01046b5,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01028ba:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01028c1:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01028c4:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01028cb:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01028d1:	76 11                	jbe    f01028e4 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028d3:	b8 83 c1 10 f0       	mov    $0xf010c183,%eax
f01028d8:	3d 79 a3 10 f0       	cmp    $0xf010a379,%eax
f01028dd:	77 19                	ja     f01028f8 <debuginfo_eip+0x61>
f01028df:	e9 aa 01 00 00       	jmp    f0102a8e <debuginfo_eip+0x1f7>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01028e4:	83 ec 04             	sub    $0x4,%esp
f01028e7:	68 bf 46 10 f0       	push   $0xf01046bf
f01028ec:	6a 7f                	push   $0x7f
f01028ee:	68 cc 46 10 f0       	push   $0xf01046cc
f01028f3:	e8 93 d7 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028f8:	80 3d 82 c1 10 f0 00 	cmpb   $0x0,0xf010c182
f01028ff:	0f 85 90 01 00 00    	jne    f0102a95 <debuginfo_eip+0x1fe>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102905:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010290c:	b8 78 a3 10 f0       	mov    $0xf010a378,%eax
f0102911:	2d e8 48 10 f0       	sub    $0xf01048e8,%eax
f0102916:	c1 f8 02             	sar    $0x2,%eax
f0102919:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010291f:	83 e8 01             	sub    $0x1,%eax
f0102922:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102925:	83 ec 08             	sub    $0x8,%esp
f0102928:	56                   	push   %esi
f0102929:	6a 64                	push   $0x64
f010292b:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010292e:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102931:	b8 e8 48 10 f0       	mov    $0xf01048e8,%eax
f0102936:	e8 66 fe ff ff       	call   f01027a1 <stab_binsearch>
	if (lfile == 0)
f010293b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010293e:	83 c4 10             	add    $0x10,%esp
f0102941:	85 c0                	test   %eax,%eax
f0102943:	0f 84 53 01 00 00    	je     f0102a9c <debuginfo_eip+0x205>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102949:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010294c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010294f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102952:	83 ec 08             	sub    $0x8,%esp
f0102955:	56                   	push   %esi
f0102956:	6a 24                	push   $0x24
f0102958:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010295b:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010295e:	b8 e8 48 10 f0       	mov    $0xf01048e8,%eax
f0102963:	e8 39 fe ff ff       	call   f01027a1 <stab_binsearch>

	if (lfun <= rfun) {
f0102968:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010296b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010296e:	83 c4 10             	add    $0x10,%esp
f0102971:	39 d0                	cmp    %edx,%eax
f0102973:	7f 40                	jg     f01029b5 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102975:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0102978:	c1 e1 02             	shl    $0x2,%ecx
f010297b:	8d b9 e8 48 10 f0    	lea    -0xfefb718(%ecx),%edi
f0102981:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102984:	8b b9 e8 48 10 f0    	mov    -0xfefb718(%ecx),%edi
f010298a:	b9 83 c1 10 f0       	mov    $0xf010c183,%ecx
f010298f:	81 e9 79 a3 10 f0    	sub    $0xf010a379,%ecx
f0102995:	39 cf                	cmp    %ecx,%edi
f0102997:	73 09                	jae    f01029a2 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102999:	81 c7 79 a3 10 f0    	add    $0xf010a379,%edi
f010299f:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01029a2:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01029a5:	8b 4f 08             	mov    0x8(%edi),%ecx
f01029a8:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01029ab:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01029ad:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01029b0:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01029b3:	eb 0f                	jmp    f01029c4 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01029b5:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01029b8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01029bb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01029be:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01029c1:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01029c4:	83 ec 08             	sub    $0x8,%esp
f01029c7:	6a 3a                	push   $0x3a
f01029c9:	ff 73 08             	pushl  0x8(%ebx)
f01029cc:	e8 59 08 00 00       	call   f010322a <strfind>
f01029d1:	2b 43 08             	sub    0x8(%ebx),%eax
f01029d4:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	which one.
	// Your code here.
	
	//	If *region_left > *region_right, then 'addr' is not contained 
	//	in any matching stab.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01029d7:	83 c4 08             	add    $0x8,%esp
f01029da:	56                   	push   %esi
f01029db:	6a 44                	push   $0x44
f01029dd:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01029e0:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01029e3:	b8 e8 48 10 f0       	mov    $0xf01048e8,%eax
f01029e8:	e8 b4 fd ff ff       	call   f01027a1 <stab_binsearch>

        if (lline > rline)
f01029ed:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01029f0:	83 c4 10             	add    $0x10,%esp
f01029f3:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f01029f6:	0f 8f a7 00 00 00    	jg     f0102aa3 <debuginfo_eip+0x20c>
        	return -1;
	info->eip_line = stabs[lline].n_desc;
f01029fc:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01029ff:	8d 04 85 e8 48 10 f0 	lea    -0xfefb718(,%eax,4),%eax
f0102a06:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f0102a0a:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102a0d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102a10:	eb 06                	jmp    f0102a18 <debuginfo_eip+0x181>
f0102a12:	83 ea 01             	sub    $0x1,%edx
f0102a15:	83 e8 0c             	sub    $0xc,%eax
f0102a18:	39 d6                	cmp    %edx,%esi
f0102a1a:	7f 34                	jg     f0102a50 <debuginfo_eip+0x1b9>
	       && stabs[lline].n_type != N_SOL
f0102a1c:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0102a20:	80 f9 84             	cmp    $0x84,%cl
f0102a23:	74 0b                	je     f0102a30 <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102a25:	80 f9 64             	cmp    $0x64,%cl
f0102a28:	75 e8                	jne    f0102a12 <debuginfo_eip+0x17b>
f0102a2a:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102a2e:	74 e2                	je     f0102a12 <debuginfo_eip+0x17b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102a30:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102a33:	8b 14 85 e8 48 10 f0 	mov    -0xfefb718(,%eax,4),%edx
f0102a3a:	b8 83 c1 10 f0       	mov    $0xf010c183,%eax
f0102a3f:	2d 79 a3 10 f0       	sub    $0xf010a379,%eax
f0102a44:	39 c2                	cmp    %eax,%edx
f0102a46:	73 08                	jae    f0102a50 <debuginfo_eip+0x1b9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102a48:	81 c2 79 a3 10 f0    	add    $0xf010a379,%edx
f0102a4e:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a50:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102a53:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a56:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a5b:	39 f2                	cmp    %esi,%edx
f0102a5d:	7d 50                	jge    f0102aaf <debuginfo_eip+0x218>
		for (lline = lfun + 1;
f0102a5f:	83 c2 01             	add    $0x1,%edx
f0102a62:	89 d0                	mov    %edx,%eax
f0102a64:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102a67:	8d 14 95 e8 48 10 f0 	lea    -0xfefb718(,%edx,4),%edx
f0102a6e:	eb 04                	jmp    f0102a74 <debuginfo_eip+0x1dd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102a70:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102a74:	39 c6                	cmp    %eax,%esi
f0102a76:	7e 32                	jle    f0102aaa <debuginfo_eip+0x213>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102a78:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102a7c:	83 c0 01             	add    $0x1,%eax
f0102a7f:	83 c2 0c             	add    $0xc,%edx
f0102a82:	80 f9 a0             	cmp    $0xa0,%cl
f0102a85:	74 e9                	je     f0102a70 <debuginfo_eip+0x1d9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a87:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a8c:	eb 21                	jmp    f0102aaf <debuginfo_eip+0x218>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102a8e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a93:	eb 1a                	jmp    f0102aaf <debuginfo_eip+0x218>
f0102a95:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a9a:	eb 13                	jmp    f0102aaf <debuginfo_eip+0x218>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102a9c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102aa1:	eb 0c                	jmp    f0102aaf <debuginfo_eip+0x218>
	//	If *region_left > *region_right, then 'addr' is not contained 
	//	in any matching stab.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);

        if (lline > rline)
        	return -1;
f0102aa3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102aa8:	eb 05                	jmp    f0102aaf <debuginfo_eip+0x218>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102aaa:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102aaf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ab2:	5b                   	pop    %ebx
f0102ab3:	5e                   	pop    %esi
f0102ab4:	5f                   	pop    %edi
f0102ab5:	5d                   	pop    %ebp
f0102ab6:	c3                   	ret    

f0102ab7 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102ab7:	55                   	push   %ebp
f0102ab8:	89 e5                	mov    %esp,%ebp
f0102aba:	57                   	push   %edi
f0102abb:	56                   	push   %esi
f0102abc:	53                   	push   %ebx
f0102abd:	83 ec 1c             	sub    $0x1c,%esp
f0102ac0:	89 c7                	mov    %eax,%edi
f0102ac2:	89 d6                	mov    %edx,%esi
f0102ac4:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ac7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102aca:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102acd:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102ad0:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102ad3:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102ad8:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102adb:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102ade:	39 d3                	cmp    %edx,%ebx
f0102ae0:	72 05                	jb     f0102ae7 <printnum+0x30>
f0102ae2:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102ae5:	77 45                	ja     f0102b2c <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102ae7:	83 ec 0c             	sub    $0xc,%esp
f0102aea:	ff 75 18             	pushl  0x18(%ebp)
f0102aed:	8b 45 14             	mov    0x14(%ebp),%eax
f0102af0:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102af3:	53                   	push   %ebx
f0102af4:	ff 75 10             	pushl  0x10(%ebp)
f0102af7:	83 ec 08             	sub    $0x8,%esp
f0102afa:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102afd:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b00:	ff 75 dc             	pushl  -0x24(%ebp)
f0102b03:	ff 75 d8             	pushl  -0x28(%ebp)
f0102b06:	e8 45 09 00 00       	call   f0103450 <__udivdi3>
f0102b0b:	83 c4 18             	add    $0x18,%esp
f0102b0e:	52                   	push   %edx
f0102b0f:	50                   	push   %eax
f0102b10:	89 f2                	mov    %esi,%edx
f0102b12:	89 f8                	mov    %edi,%eax
f0102b14:	e8 9e ff ff ff       	call   f0102ab7 <printnum>
f0102b19:	83 c4 20             	add    $0x20,%esp
f0102b1c:	eb 18                	jmp    f0102b36 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102b1e:	83 ec 08             	sub    $0x8,%esp
f0102b21:	56                   	push   %esi
f0102b22:	ff 75 18             	pushl  0x18(%ebp)
f0102b25:	ff d7                	call   *%edi
f0102b27:	83 c4 10             	add    $0x10,%esp
f0102b2a:	eb 03                	jmp    f0102b2f <printnum+0x78>
f0102b2c:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102b2f:	83 eb 01             	sub    $0x1,%ebx
f0102b32:	85 db                	test   %ebx,%ebx
f0102b34:	7f e8                	jg     f0102b1e <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102b36:	83 ec 08             	sub    $0x8,%esp
f0102b39:	56                   	push   %esi
f0102b3a:	83 ec 04             	sub    $0x4,%esp
f0102b3d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102b40:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b43:	ff 75 dc             	pushl  -0x24(%ebp)
f0102b46:	ff 75 d8             	pushl  -0x28(%ebp)
f0102b49:	e8 32 0a 00 00       	call   f0103580 <__umoddi3>
f0102b4e:	83 c4 14             	add    $0x14,%esp
f0102b51:	0f be 80 da 46 10 f0 	movsbl -0xfefb926(%eax),%eax
f0102b58:	50                   	push   %eax
f0102b59:	ff d7                	call   *%edi
}
f0102b5b:	83 c4 10             	add    $0x10,%esp
f0102b5e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b61:	5b                   	pop    %ebx
f0102b62:	5e                   	pop    %esi
f0102b63:	5f                   	pop    %edi
f0102b64:	5d                   	pop    %ebp
f0102b65:	c3                   	ret    

f0102b66 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102b66:	55                   	push   %ebp
f0102b67:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102b69:	83 fa 01             	cmp    $0x1,%edx
f0102b6c:	7e 0e                	jle    f0102b7c <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102b6e:	8b 10                	mov    (%eax),%edx
f0102b70:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102b73:	89 08                	mov    %ecx,(%eax)
f0102b75:	8b 02                	mov    (%edx),%eax
f0102b77:	8b 52 04             	mov    0x4(%edx),%edx
f0102b7a:	eb 22                	jmp    f0102b9e <getuint+0x38>
	else if (lflag)
f0102b7c:	85 d2                	test   %edx,%edx
f0102b7e:	74 10                	je     f0102b90 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102b80:	8b 10                	mov    (%eax),%edx
f0102b82:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b85:	89 08                	mov    %ecx,(%eax)
f0102b87:	8b 02                	mov    (%edx),%eax
f0102b89:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b8e:	eb 0e                	jmp    f0102b9e <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102b90:	8b 10                	mov    (%eax),%edx
f0102b92:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b95:	89 08                	mov    %ecx,(%eax)
f0102b97:	8b 02                	mov    (%edx),%eax
f0102b99:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102b9e:	5d                   	pop    %ebp
f0102b9f:	c3                   	ret    

f0102ba0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102ba0:	55                   	push   %ebp
f0102ba1:	89 e5                	mov    %esp,%ebp
f0102ba3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102ba6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102baa:	8b 10                	mov    (%eax),%edx
f0102bac:	3b 50 04             	cmp    0x4(%eax),%edx
f0102baf:	73 0a                	jae    f0102bbb <sprintputch+0x1b>
		*b->buf++ = ch;
f0102bb1:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102bb4:	89 08                	mov    %ecx,(%eax)
f0102bb6:	8b 45 08             	mov    0x8(%ebp),%eax
f0102bb9:	88 02                	mov    %al,(%edx)
}
f0102bbb:	5d                   	pop    %ebp
f0102bbc:	c3                   	ret    

f0102bbd <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102bbd:	55                   	push   %ebp
f0102bbe:	89 e5                	mov    %esp,%ebp
f0102bc0:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102bc3:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102bc6:	50                   	push   %eax
f0102bc7:	ff 75 10             	pushl  0x10(%ebp)
f0102bca:	ff 75 0c             	pushl  0xc(%ebp)
f0102bcd:	ff 75 08             	pushl  0x8(%ebp)
f0102bd0:	e8 05 00 00 00       	call   f0102bda <vprintfmt>
	va_end(ap);
}
f0102bd5:	83 c4 10             	add    $0x10,%esp
f0102bd8:	c9                   	leave  
f0102bd9:	c3                   	ret    

f0102bda <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102bda:	55                   	push   %ebp
f0102bdb:	89 e5                	mov    %esp,%ebp
f0102bdd:	57                   	push   %edi
f0102bde:	56                   	push   %esi
f0102bdf:	53                   	push   %ebx
f0102be0:	83 ec 2c             	sub    $0x2c,%esp
f0102be3:	8b 75 08             	mov    0x8(%ebp),%esi
f0102be6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102be9:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102bec:	eb 12                	jmp    f0102c00 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102bee:	85 c0                	test   %eax,%eax
f0102bf0:	0f 84 89 03 00 00    	je     f0102f7f <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0102bf6:	83 ec 08             	sub    $0x8,%esp
f0102bf9:	53                   	push   %ebx
f0102bfa:	50                   	push   %eax
f0102bfb:	ff d6                	call   *%esi
f0102bfd:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102c00:	83 c7 01             	add    $0x1,%edi
f0102c03:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102c07:	83 f8 25             	cmp    $0x25,%eax
f0102c0a:	75 e2                	jne    f0102bee <vprintfmt+0x14>
f0102c0c:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102c10:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102c17:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c1e:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102c25:	ba 00 00 00 00       	mov    $0x0,%edx
f0102c2a:	eb 07                	jmp    f0102c33 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c2c:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102c2f:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c33:	8d 47 01             	lea    0x1(%edi),%eax
f0102c36:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102c39:	0f b6 07             	movzbl (%edi),%eax
f0102c3c:	0f b6 c8             	movzbl %al,%ecx
f0102c3f:	83 e8 23             	sub    $0x23,%eax
f0102c42:	3c 55                	cmp    $0x55,%al
f0102c44:	0f 87 1a 03 00 00    	ja     f0102f64 <vprintfmt+0x38a>
f0102c4a:	0f b6 c0             	movzbl %al,%eax
f0102c4d:	ff 24 85 64 47 10 f0 	jmp    *-0xfefb89c(,%eax,4)
f0102c54:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102c57:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102c5b:	eb d6                	jmp    f0102c33 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c5d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c60:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c65:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102c68:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102c6b:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102c6f:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102c72:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102c75:	83 fa 09             	cmp    $0x9,%edx
f0102c78:	77 39                	ja     f0102cb3 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102c7a:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102c7d:	eb e9                	jmp    f0102c68 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102c7f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c82:	8d 48 04             	lea    0x4(%eax),%ecx
f0102c85:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102c88:	8b 00                	mov    (%eax),%eax
f0102c8a:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c8d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102c90:	eb 27                	jmp    f0102cb9 <vprintfmt+0xdf>
f0102c92:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c95:	85 c0                	test   %eax,%eax
f0102c97:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102c9c:	0f 49 c8             	cmovns %eax,%ecx
f0102c9f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ca2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ca5:	eb 8c                	jmp    f0102c33 <vprintfmt+0x59>
f0102ca7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102caa:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102cb1:	eb 80                	jmp    f0102c33 <vprintfmt+0x59>
f0102cb3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102cb6:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102cb9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102cbd:	0f 89 70 ff ff ff    	jns    f0102c33 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102cc3:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102cc6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102cc9:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102cd0:	e9 5e ff ff ff       	jmp    f0102c33 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102cd5:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cd8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102cdb:	e9 53 ff ff ff       	jmp    f0102c33 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102ce0:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ce3:	8d 50 04             	lea    0x4(%eax),%edx
f0102ce6:	89 55 14             	mov    %edx,0x14(%ebp)
f0102ce9:	83 ec 08             	sub    $0x8,%esp
f0102cec:	53                   	push   %ebx
f0102ced:	ff 30                	pushl  (%eax)
f0102cef:	ff d6                	call   *%esi
			break;
f0102cf1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cf4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102cf7:	e9 04 ff ff ff       	jmp    f0102c00 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102cfc:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cff:	8d 50 04             	lea    0x4(%eax),%edx
f0102d02:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d05:	8b 00                	mov    (%eax),%eax
f0102d07:	99                   	cltd   
f0102d08:	31 d0                	xor    %edx,%eax
f0102d0a:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102d0c:	83 f8 06             	cmp    $0x6,%eax
f0102d0f:	7f 0b                	jg     f0102d1c <vprintfmt+0x142>
f0102d11:	8b 14 85 bc 48 10 f0 	mov    -0xfefb744(,%eax,4),%edx
f0102d18:	85 d2                	test   %edx,%edx
f0102d1a:	75 18                	jne    f0102d34 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102d1c:	50                   	push   %eax
f0102d1d:	68 f2 46 10 f0       	push   $0xf01046f2
f0102d22:	53                   	push   %ebx
f0102d23:	56                   	push   %esi
f0102d24:	e8 94 fe ff ff       	call   f0102bbd <printfmt>
f0102d29:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d2c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102d2f:	e9 cc fe ff ff       	jmp    f0102c00 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102d34:	52                   	push   %edx
f0102d35:	68 0a 44 10 f0       	push   $0xf010440a
f0102d3a:	53                   	push   %ebx
f0102d3b:	56                   	push   %esi
f0102d3c:	e8 7c fe ff ff       	call   f0102bbd <printfmt>
f0102d41:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d44:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d47:	e9 b4 fe ff ff       	jmp    f0102c00 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102d4c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d4f:	8d 50 04             	lea    0x4(%eax),%edx
f0102d52:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d55:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102d57:	85 ff                	test   %edi,%edi
f0102d59:	b8 eb 46 10 f0       	mov    $0xf01046eb,%eax
f0102d5e:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102d61:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102d65:	0f 8e 94 00 00 00    	jle    f0102dff <vprintfmt+0x225>
f0102d6b:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102d6f:	0f 84 98 00 00 00    	je     f0102e0d <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d75:	83 ec 08             	sub    $0x8,%esp
f0102d78:	ff 75 d0             	pushl  -0x30(%ebp)
f0102d7b:	57                   	push   %edi
f0102d7c:	e8 5f 03 00 00       	call   f01030e0 <strnlen>
f0102d81:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102d84:	29 c1                	sub    %eax,%ecx
f0102d86:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102d89:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102d8c:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102d90:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d93:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102d96:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d98:	eb 0f                	jmp    f0102da9 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102d9a:	83 ec 08             	sub    $0x8,%esp
f0102d9d:	53                   	push   %ebx
f0102d9e:	ff 75 e0             	pushl  -0x20(%ebp)
f0102da1:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102da3:	83 ef 01             	sub    $0x1,%edi
f0102da6:	83 c4 10             	add    $0x10,%esp
f0102da9:	85 ff                	test   %edi,%edi
f0102dab:	7f ed                	jg     f0102d9a <vprintfmt+0x1c0>
f0102dad:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102db0:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102db3:	85 c9                	test   %ecx,%ecx
f0102db5:	b8 00 00 00 00       	mov    $0x0,%eax
f0102dba:	0f 49 c1             	cmovns %ecx,%eax
f0102dbd:	29 c1                	sub    %eax,%ecx
f0102dbf:	89 75 08             	mov    %esi,0x8(%ebp)
f0102dc2:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102dc5:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102dc8:	89 cb                	mov    %ecx,%ebx
f0102dca:	eb 4d                	jmp    f0102e19 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102dcc:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102dd0:	74 1b                	je     f0102ded <vprintfmt+0x213>
f0102dd2:	0f be c0             	movsbl %al,%eax
f0102dd5:	83 e8 20             	sub    $0x20,%eax
f0102dd8:	83 f8 5e             	cmp    $0x5e,%eax
f0102ddb:	76 10                	jbe    f0102ded <vprintfmt+0x213>
					putch('?', putdat);
f0102ddd:	83 ec 08             	sub    $0x8,%esp
f0102de0:	ff 75 0c             	pushl  0xc(%ebp)
f0102de3:	6a 3f                	push   $0x3f
f0102de5:	ff 55 08             	call   *0x8(%ebp)
f0102de8:	83 c4 10             	add    $0x10,%esp
f0102deb:	eb 0d                	jmp    f0102dfa <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102ded:	83 ec 08             	sub    $0x8,%esp
f0102df0:	ff 75 0c             	pushl  0xc(%ebp)
f0102df3:	52                   	push   %edx
f0102df4:	ff 55 08             	call   *0x8(%ebp)
f0102df7:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102dfa:	83 eb 01             	sub    $0x1,%ebx
f0102dfd:	eb 1a                	jmp    f0102e19 <vprintfmt+0x23f>
f0102dff:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e02:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102e05:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102e08:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102e0b:	eb 0c                	jmp    f0102e19 <vprintfmt+0x23f>
f0102e0d:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e10:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102e13:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102e16:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102e19:	83 c7 01             	add    $0x1,%edi
f0102e1c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102e20:	0f be d0             	movsbl %al,%edx
f0102e23:	85 d2                	test   %edx,%edx
f0102e25:	74 23                	je     f0102e4a <vprintfmt+0x270>
f0102e27:	85 f6                	test   %esi,%esi
f0102e29:	78 a1                	js     f0102dcc <vprintfmt+0x1f2>
f0102e2b:	83 ee 01             	sub    $0x1,%esi
f0102e2e:	79 9c                	jns    f0102dcc <vprintfmt+0x1f2>
f0102e30:	89 df                	mov    %ebx,%edi
f0102e32:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e35:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102e38:	eb 18                	jmp    f0102e52 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102e3a:	83 ec 08             	sub    $0x8,%esp
f0102e3d:	53                   	push   %ebx
f0102e3e:	6a 20                	push   $0x20
f0102e40:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102e42:	83 ef 01             	sub    $0x1,%edi
f0102e45:	83 c4 10             	add    $0x10,%esp
f0102e48:	eb 08                	jmp    f0102e52 <vprintfmt+0x278>
f0102e4a:	89 df                	mov    %ebx,%edi
f0102e4c:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e4f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102e52:	85 ff                	test   %edi,%edi
f0102e54:	7f e4                	jg     f0102e3a <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e56:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e59:	e9 a2 fd ff ff       	jmp    f0102c00 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e5e:	83 fa 01             	cmp    $0x1,%edx
f0102e61:	7e 16                	jle    f0102e79 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102e63:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e66:	8d 50 08             	lea    0x8(%eax),%edx
f0102e69:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e6c:	8b 50 04             	mov    0x4(%eax),%edx
f0102e6f:	8b 00                	mov    (%eax),%eax
f0102e71:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e74:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102e77:	eb 32                	jmp    f0102eab <vprintfmt+0x2d1>
	else if (lflag)
f0102e79:	85 d2                	test   %edx,%edx
f0102e7b:	74 18                	je     f0102e95 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102e7d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e80:	8d 50 04             	lea    0x4(%eax),%edx
f0102e83:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e86:	8b 00                	mov    (%eax),%eax
f0102e88:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e8b:	89 c1                	mov    %eax,%ecx
f0102e8d:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e90:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e93:	eb 16                	jmp    f0102eab <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102e95:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e98:	8d 50 04             	lea    0x4(%eax),%edx
f0102e9b:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e9e:	8b 00                	mov    (%eax),%eax
f0102ea0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ea3:	89 c1                	mov    %eax,%ecx
f0102ea5:	c1 f9 1f             	sar    $0x1f,%ecx
f0102ea8:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102eab:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102eae:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102eb1:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102eb6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102eba:	79 74                	jns    f0102f30 <vprintfmt+0x356>
				putch('-', putdat);
f0102ebc:	83 ec 08             	sub    $0x8,%esp
f0102ebf:	53                   	push   %ebx
f0102ec0:	6a 2d                	push   $0x2d
f0102ec2:	ff d6                	call   *%esi
				num = -(long long) num;
f0102ec4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102ec7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102eca:	f7 d8                	neg    %eax
f0102ecc:	83 d2 00             	adc    $0x0,%edx
f0102ecf:	f7 da                	neg    %edx
f0102ed1:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102ed4:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102ed9:	eb 55                	jmp    f0102f30 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102edb:	8d 45 14             	lea    0x14(%ebp),%eax
f0102ede:	e8 83 fc ff ff       	call   f0102b66 <getuint>
			base = 10;
f0102ee3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102ee8:	eb 46                	jmp    f0102f30 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0102eea:	8d 45 14             	lea    0x14(%ebp),%eax
f0102eed:	e8 74 fc ff ff       	call   f0102b66 <getuint>
			base = 8;						
f0102ef2:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102ef7:	eb 37                	jmp    f0102f30 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0102ef9:	83 ec 08             	sub    $0x8,%esp
f0102efc:	53                   	push   %ebx
f0102efd:	6a 30                	push   $0x30
f0102eff:	ff d6                	call   *%esi
			putch('x', putdat);
f0102f01:	83 c4 08             	add    $0x8,%esp
f0102f04:	53                   	push   %ebx
f0102f05:	6a 78                	push   $0x78
f0102f07:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102f09:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f0c:	8d 50 04             	lea    0x4(%eax),%edx
f0102f0f:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102f12:	8b 00                	mov    (%eax),%eax
f0102f14:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102f19:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102f1c:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102f21:	eb 0d                	jmp    f0102f30 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102f23:	8d 45 14             	lea    0x14(%ebp),%eax
f0102f26:	e8 3b fc ff ff       	call   f0102b66 <getuint>
			base = 16;
f0102f2b:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102f30:	83 ec 0c             	sub    $0xc,%esp
f0102f33:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102f37:	57                   	push   %edi
f0102f38:	ff 75 e0             	pushl  -0x20(%ebp)
f0102f3b:	51                   	push   %ecx
f0102f3c:	52                   	push   %edx
f0102f3d:	50                   	push   %eax
f0102f3e:	89 da                	mov    %ebx,%edx
f0102f40:	89 f0                	mov    %esi,%eax
f0102f42:	e8 70 fb ff ff       	call   f0102ab7 <printnum>
			break;
f0102f47:	83 c4 20             	add    $0x20,%esp
f0102f4a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102f4d:	e9 ae fc ff ff       	jmp    f0102c00 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102f52:	83 ec 08             	sub    $0x8,%esp
f0102f55:	53                   	push   %ebx
f0102f56:	51                   	push   %ecx
f0102f57:	ff d6                	call   *%esi
			break;
f0102f59:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102f5c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102f5f:	e9 9c fc ff ff       	jmp    f0102c00 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102f64:	83 ec 08             	sub    $0x8,%esp
f0102f67:	53                   	push   %ebx
f0102f68:	6a 25                	push   $0x25
f0102f6a:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102f6c:	83 c4 10             	add    $0x10,%esp
f0102f6f:	eb 03                	jmp    f0102f74 <vprintfmt+0x39a>
f0102f71:	83 ef 01             	sub    $0x1,%edi
f0102f74:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102f78:	75 f7                	jne    f0102f71 <vprintfmt+0x397>
f0102f7a:	e9 81 fc ff ff       	jmp    f0102c00 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102f7f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f82:	5b                   	pop    %ebx
f0102f83:	5e                   	pop    %esi
f0102f84:	5f                   	pop    %edi
f0102f85:	5d                   	pop    %ebp
f0102f86:	c3                   	ret    

f0102f87 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102f87:	55                   	push   %ebp
f0102f88:	89 e5                	mov    %esp,%ebp
f0102f8a:	83 ec 18             	sub    $0x18,%esp
f0102f8d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f90:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102f93:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102f96:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102f9a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102f9d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102fa4:	85 c0                	test   %eax,%eax
f0102fa6:	74 26                	je     f0102fce <vsnprintf+0x47>
f0102fa8:	85 d2                	test   %edx,%edx
f0102faa:	7e 22                	jle    f0102fce <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102fac:	ff 75 14             	pushl  0x14(%ebp)
f0102faf:	ff 75 10             	pushl  0x10(%ebp)
f0102fb2:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102fb5:	50                   	push   %eax
f0102fb6:	68 a0 2b 10 f0       	push   $0xf0102ba0
f0102fbb:	e8 1a fc ff ff       	call   f0102bda <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102fc0:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102fc3:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102fc6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102fc9:	83 c4 10             	add    $0x10,%esp
f0102fcc:	eb 05                	jmp    f0102fd3 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102fce:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102fd3:	c9                   	leave  
f0102fd4:	c3                   	ret    

f0102fd5 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102fd5:	55                   	push   %ebp
f0102fd6:	89 e5                	mov    %esp,%ebp
f0102fd8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102fdb:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102fde:	50                   	push   %eax
f0102fdf:	ff 75 10             	pushl  0x10(%ebp)
f0102fe2:	ff 75 0c             	pushl  0xc(%ebp)
f0102fe5:	ff 75 08             	pushl  0x8(%ebp)
f0102fe8:	e8 9a ff ff ff       	call   f0102f87 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102fed:	c9                   	leave  
f0102fee:	c3                   	ret    

f0102fef <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102fef:	55                   	push   %ebp
f0102ff0:	89 e5                	mov    %esp,%ebp
f0102ff2:	57                   	push   %edi
f0102ff3:	56                   	push   %esi
f0102ff4:	53                   	push   %ebx
f0102ff5:	83 ec 0c             	sub    $0xc,%esp
f0102ff8:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102ffb:	85 c0                	test   %eax,%eax
f0102ffd:	74 11                	je     f0103010 <readline+0x21>
		cprintf("%s", prompt);
f0102fff:	83 ec 08             	sub    $0x8,%esp
f0103002:	50                   	push   %eax
f0103003:	68 0a 44 10 f0       	push   $0xf010440a
f0103008:	e8 80 f7 ff ff       	call   f010278d <cprintf>
f010300d:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103010:	83 ec 0c             	sub    $0xc,%esp
f0103013:	6a 00                	push   $0x0
f0103015:	e8 07 d6 ff ff       	call   f0100621 <iscons>
f010301a:	89 c7                	mov    %eax,%edi
f010301c:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010301f:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103024:	e8 e7 d5 ff ff       	call   f0100610 <getchar>
f0103029:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010302b:	85 c0                	test   %eax,%eax
f010302d:	79 18                	jns    f0103047 <readline+0x58>
			cprintf("read error: %e\n", c);
f010302f:	83 ec 08             	sub    $0x8,%esp
f0103032:	50                   	push   %eax
f0103033:	68 d8 48 10 f0       	push   $0xf01048d8
f0103038:	e8 50 f7 ff ff       	call   f010278d <cprintf>
			return NULL;
f010303d:	83 c4 10             	add    $0x10,%esp
f0103040:	b8 00 00 00 00       	mov    $0x0,%eax
f0103045:	eb 79                	jmp    f01030c0 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103047:	83 f8 08             	cmp    $0x8,%eax
f010304a:	0f 94 c2             	sete   %dl
f010304d:	83 f8 7f             	cmp    $0x7f,%eax
f0103050:	0f 94 c0             	sete   %al
f0103053:	08 c2                	or     %al,%dl
f0103055:	74 1a                	je     f0103071 <readline+0x82>
f0103057:	85 f6                	test   %esi,%esi
f0103059:	7e 16                	jle    f0103071 <readline+0x82>
			if (echoing)
f010305b:	85 ff                	test   %edi,%edi
f010305d:	74 0d                	je     f010306c <readline+0x7d>
				cputchar('\b');
f010305f:	83 ec 0c             	sub    $0xc,%esp
f0103062:	6a 08                	push   $0x8
f0103064:	e8 97 d5 ff ff       	call   f0100600 <cputchar>
f0103069:	83 c4 10             	add    $0x10,%esp
			i--;
f010306c:	83 ee 01             	sub    $0x1,%esi
f010306f:	eb b3                	jmp    f0103024 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103071:	83 fb 1f             	cmp    $0x1f,%ebx
f0103074:	7e 23                	jle    f0103099 <readline+0xaa>
f0103076:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010307c:	7f 1b                	jg     f0103099 <readline+0xaa>
			if (echoing)
f010307e:	85 ff                	test   %edi,%edi
f0103080:	74 0c                	je     f010308e <readline+0x9f>
				cputchar(c);
f0103082:	83 ec 0c             	sub    $0xc,%esp
f0103085:	53                   	push   %ebx
f0103086:	e8 75 d5 ff ff       	call   f0100600 <cputchar>
f010308b:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010308e:	88 9e 40 75 11 f0    	mov    %bl,-0xfee8ac0(%esi)
f0103094:	8d 76 01             	lea    0x1(%esi),%esi
f0103097:	eb 8b                	jmp    f0103024 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103099:	83 fb 0a             	cmp    $0xa,%ebx
f010309c:	74 05                	je     f01030a3 <readline+0xb4>
f010309e:	83 fb 0d             	cmp    $0xd,%ebx
f01030a1:	75 81                	jne    f0103024 <readline+0x35>
			if (echoing)
f01030a3:	85 ff                	test   %edi,%edi
f01030a5:	74 0d                	je     f01030b4 <readline+0xc5>
				cputchar('\n');
f01030a7:	83 ec 0c             	sub    $0xc,%esp
f01030aa:	6a 0a                	push   $0xa
f01030ac:	e8 4f d5 ff ff       	call   f0100600 <cputchar>
f01030b1:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01030b4:	c6 86 40 75 11 f0 00 	movb   $0x0,-0xfee8ac0(%esi)
			return buf;
f01030bb:	b8 40 75 11 f0       	mov    $0xf0117540,%eax
		}
	}
}
f01030c0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030c3:	5b                   	pop    %ebx
f01030c4:	5e                   	pop    %esi
f01030c5:	5f                   	pop    %edi
f01030c6:	5d                   	pop    %ebp
f01030c7:	c3                   	ret    

f01030c8 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01030c8:	55                   	push   %ebp
f01030c9:	89 e5                	mov    %esp,%ebp
f01030cb:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01030ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01030d3:	eb 03                	jmp    f01030d8 <strlen+0x10>
		n++;
f01030d5:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01030d8:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01030dc:	75 f7                	jne    f01030d5 <strlen+0xd>
		n++;
	return n;
}
f01030de:	5d                   	pop    %ebp
f01030df:	c3                   	ret    

f01030e0 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01030e0:	55                   	push   %ebp
f01030e1:	89 e5                	mov    %esp,%ebp
f01030e3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01030e6:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01030e9:	ba 00 00 00 00       	mov    $0x0,%edx
f01030ee:	eb 03                	jmp    f01030f3 <strnlen+0x13>
		n++;
f01030f0:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01030f3:	39 c2                	cmp    %eax,%edx
f01030f5:	74 08                	je     f01030ff <strnlen+0x1f>
f01030f7:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01030fb:	75 f3                	jne    f01030f0 <strnlen+0x10>
f01030fd:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01030ff:	5d                   	pop    %ebp
f0103100:	c3                   	ret    

f0103101 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103101:	55                   	push   %ebp
f0103102:	89 e5                	mov    %esp,%ebp
f0103104:	53                   	push   %ebx
f0103105:	8b 45 08             	mov    0x8(%ebp),%eax
f0103108:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010310b:	89 c2                	mov    %eax,%edx
f010310d:	83 c2 01             	add    $0x1,%edx
f0103110:	83 c1 01             	add    $0x1,%ecx
f0103113:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103117:	88 5a ff             	mov    %bl,-0x1(%edx)
f010311a:	84 db                	test   %bl,%bl
f010311c:	75 ef                	jne    f010310d <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010311e:	5b                   	pop    %ebx
f010311f:	5d                   	pop    %ebp
f0103120:	c3                   	ret    

f0103121 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103121:	55                   	push   %ebp
f0103122:	89 e5                	mov    %esp,%ebp
f0103124:	53                   	push   %ebx
f0103125:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103128:	53                   	push   %ebx
f0103129:	e8 9a ff ff ff       	call   f01030c8 <strlen>
f010312e:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103131:	ff 75 0c             	pushl  0xc(%ebp)
f0103134:	01 d8                	add    %ebx,%eax
f0103136:	50                   	push   %eax
f0103137:	e8 c5 ff ff ff       	call   f0103101 <strcpy>
	return dst;
}
f010313c:	89 d8                	mov    %ebx,%eax
f010313e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103141:	c9                   	leave  
f0103142:	c3                   	ret    

f0103143 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103143:	55                   	push   %ebp
f0103144:	89 e5                	mov    %esp,%ebp
f0103146:	56                   	push   %esi
f0103147:	53                   	push   %ebx
f0103148:	8b 75 08             	mov    0x8(%ebp),%esi
f010314b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010314e:	89 f3                	mov    %esi,%ebx
f0103150:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103153:	89 f2                	mov    %esi,%edx
f0103155:	eb 0f                	jmp    f0103166 <strncpy+0x23>
		*dst++ = *src;
f0103157:	83 c2 01             	add    $0x1,%edx
f010315a:	0f b6 01             	movzbl (%ecx),%eax
f010315d:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103160:	80 39 01             	cmpb   $0x1,(%ecx)
f0103163:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103166:	39 da                	cmp    %ebx,%edx
f0103168:	75 ed                	jne    f0103157 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010316a:	89 f0                	mov    %esi,%eax
f010316c:	5b                   	pop    %ebx
f010316d:	5e                   	pop    %esi
f010316e:	5d                   	pop    %ebp
f010316f:	c3                   	ret    

f0103170 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103170:	55                   	push   %ebp
f0103171:	89 e5                	mov    %esp,%ebp
f0103173:	56                   	push   %esi
f0103174:	53                   	push   %ebx
f0103175:	8b 75 08             	mov    0x8(%ebp),%esi
f0103178:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010317b:	8b 55 10             	mov    0x10(%ebp),%edx
f010317e:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103180:	85 d2                	test   %edx,%edx
f0103182:	74 21                	je     f01031a5 <strlcpy+0x35>
f0103184:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103188:	89 f2                	mov    %esi,%edx
f010318a:	eb 09                	jmp    f0103195 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010318c:	83 c2 01             	add    $0x1,%edx
f010318f:	83 c1 01             	add    $0x1,%ecx
f0103192:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103195:	39 c2                	cmp    %eax,%edx
f0103197:	74 09                	je     f01031a2 <strlcpy+0x32>
f0103199:	0f b6 19             	movzbl (%ecx),%ebx
f010319c:	84 db                	test   %bl,%bl
f010319e:	75 ec                	jne    f010318c <strlcpy+0x1c>
f01031a0:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01031a2:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01031a5:	29 f0                	sub    %esi,%eax
}
f01031a7:	5b                   	pop    %ebx
f01031a8:	5e                   	pop    %esi
f01031a9:	5d                   	pop    %ebp
f01031aa:	c3                   	ret    

f01031ab <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01031ab:	55                   	push   %ebp
f01031ac:	89 e5                	mov    %esp,%ebp
f01031ae:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01031b1:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01031b4:	eb 06                	jmp    f01031bc <strcmp+0x11>
		p++, q++;
f01031b6:	83 c1 01             	add    $0x1,%ecx
f01031b9:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01031bc:	0f b6 01             	movzbl (%ecx),%eax
f01031bf:	84 c0                	test   %al,%al
f01031c1:	74 04                	je     f01031c7 <strcmp+0x1c>
f01031c3:	3a 02                	cmp    (%edx),%al
f01031c5:	74 ef                	je     f01031b6 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01031c7:	0f b6 c0             	movzbl %al,%eax
f01031ca:	0f b6 12             	movzbl (%edx),%edx
f01031cd:	29 d0                	sub    %edx,%eax
}
f01031cf:	5d                   	pop    %ebp
f01031d0:	c3                   	ret    

f01031d1 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01031d1:	55                   	push   %ebp
f01031d2:	89 e5                	mov    %esp,%ebp
f01031d4:	53                   	push   %ebx
f01031d5:	8b 45 08             	mov    0x8(%ebp),%eax
f01031d8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01031db:	89 c3                	mov    %eax,%ebx
f01031dd:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01031e0:	eb 06                	jmp    f01031e8 <strncmp+0x17>
		n--, p++, q++;
f01031e2:	83 c0 01             	add    $0x1,%eax
f01031e5:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01031e8:	39 d8                	cmp    %ebx,%eax
f01031ea:	74 15                	je     f0103201 <strncmp+0x30>
f01031ec:	0f b6 08             	movzbl (%eax),%ecx
f01031ef:	84 c9                	test   %cl,%cl
f01031f1:	74 04                	je     f01031f7 <strncmp+0x26>
f01031f3:	3a 0a                	cmp    (%edx),%cl
f01031f5:	74 eb                	je     f01031e2 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01031f7:	0f b6 00             	movzbl (%eax),%eax
f01031fa:	0f b6 12             	movzbl (%edx),%edx
f01031fd:	29 d0                	sub    %edx,%eax
f01031ff:	eb 05                	jmp    f0103206 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103201:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103206:	5b                   	pop    %ebx
f0103207:	5d                   	pop    %ebp
f0103208:	c3                   	ret    

f0103209 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103209:	55                   	push   %ebp
f010320a:	89 e5                	mov    %esp,%ebp
f010320c:	8b 45 08             	mov    0x8(%ebp),%eax
f010320f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103213:	eb 07                	jmp    f010321c <strchr+0x13>
		if (*s == c)
f0103215:	38 ca                	cmp    %cl,%dl
f0103217:	74 0f                	je     f0103228 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103219:	83 c0 01             	add    $0x1,%eax
f010321c:	0f b6 10             	movzbl (%eax),%edx
f010321f:	84 d2                	test   %dl,%dl
f0103221:	75 f2                	jne    f0103215 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103223:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103228:	5d                   	pop    %ebp
f0103229:	c3                   	ret    

f010322a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010322a:	55                   	push   %ebp
f010322b:	89 e5                	mov    %esp,%ebp
f010322d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103230:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103234:	eb 03                	jmp    f0103239 <strfind+0xf>
f0103236:	83 c0 01             	add    $0x1,%eax
f0103239:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010323c:	38 ca                	cmp    %cl,%dl
f010323e:	74 04                	je     f0103244 <strfind+0x1a>
f0103240:	84 d2                	test   %dl,%dl
f0103242:	75 f2                	jne    f0103236 <strfind+0xc>
			break;
	return (char *) s;
}
f0103244:	5d                   	pop    %ebp
f0103245:	c3                   	ret    

f0103246 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103246:	55                   	push   %ebp
f0103247:	89 e5                	mov    %esp,%ebp
f0103249:	57                   	push   %edi
f010324a:	56                   	push   %esi
f010324b:	53                   	push   %ebx
f010324c:	8b 7d 08             	mov    0x8(%ebp),%edi
f010324f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103252:	85 c9                	test   %ecx,%ecx
f0103254:	74 36                	je     f010328c <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103256:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010325c:	75 28                	jne    f0103286 <memset+0x40>
f010325e:	f6 c1 03             	test   $0x3,%cl
f0103261:	75 23                	jne    f0103286 <memset+0x40>
		c &= 0xFF;
f0103263:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103267:	89 d3                	mov    %edx,%ebx
f0103269:	c1 e3 08             	shl    $0x8,%ebx
f010326c:	89 d6                	mov    %edx,%esi
f010326e:	c1 e6 18             	shl    $0x18,%esi
f0103271:	89 d0                	mov    %edx,%eax
f0103273:	c1 e0 10             	shl    $0x10,%eax
f0103276:	09 f0                	or     %esi,%eax
f0103278:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010327a:	89 d8                	mov    %ebx,%eax
f010327c:	09 d0                	or     %edx,%eax
f010327e:	c1 e9 02             	shr    $0x2,%ecx
f0103281:	fc                   	cld    
f0103282:	f3 ab                	rep stos %eax,%es:(%edi)
f0103284:	eb 06                	jmp    f010328c <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103286:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103289:	fc                   	cld    
f010328a:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010328c:	89 f8                	mov    %edi,%eax
f010328e:	5b                   	pop    %ebx
f010328f:	5e                   	pop    %esi
f0103290:	5f                   	pop    %edi
f0103291:	5d                   	pop    %ebp
f0103292:	c3                   	ret    

f0103293 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103293:	55                   	push   %ebp
f0103294:	89 e5                	mov    %esp,%ebp
f0103296:	57                   	push   %edi
f0103297:	56                   	push   %esi
f0103298:	8b 45 08             	mov    0x8(%ebp),%eax
f010329b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010329e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01032a1:	39 c6                	cmp    %eax,%esi
f01032a3:	73 35                	jae    f01032da <memmove+0x47>
f01032a5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01032a8:	39 d0                	cmp    %edx,%eax
f01032aa:	73 2e                	jae    f01032da <memmove+0x47>
		s += n;
		d += n;
f01032ac:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01032af:	89 d6                	mov    %edx,%esi
f01032b1:	09 fe                	or     %edi,%esi
f01032b3:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01032b9:	75 13                	jne    f01032ce <memmove+0x3b>
f01032bb:	f6 c1 03             	test   $0x3,%cl
f01032be:	75 0e                	jne    f01032ce <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01032c0:	83 ef 04             	sub    $0x4,%edi
f01032c3:	8d 72 fc             	lea    -0x4(%edx),%esi
f01032c6:	c1 e9 02             	shr    $0x2,%ecx
f01032c9:	fd                   	std    
f01032ca:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032cc:	eb 09                	jmp    f01032d7 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01032ce:	83 ef 01             	sub    $0x1,%edi
f01032d1:	8d 72 ff             	lea    -0x1(%edx),%esi
f01032d4:	fd                   	std    
f01032d5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01032d7:	fc                   	cld    
f01032d8:	eb 1d                	jmp    f01032f7 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01032da:	89 f2                	mov    %esi,%edx
f01032dc:	09 c2                	or     %eax,%edx
f01032de:	f6 c2 03             	test   $0x3,%dl
f01032e1:	75 0f                	jne    f01032f2 <memmove+0x5f>
f01032e3:	f6 c1 03             	test   $0x3,%cl
f01032e6:	75 0a                	jne    f01032f2 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01032e8:	c1 e9 02             	shr    $0x2,%ecx
f01032eb:	89 c7                	mov    %eax,%edi
f01032ed:	fc                   	cld    
f01032ee:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032f0:	eb 05                	jmp    f01032f7 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01032f2:	89 c7                	mov    %eax,%edi
f01032f4:	fc                   	cld    
f01032f5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01032f7:	5e                   	pop    %esi
f01032f8:	5f                   	pop    %edi
f01032f9:	5d                   	pop    %ebp
f01032fa:	c3                   	ret    

f01032fb <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01032fb:	55                   	push   %ebp
f01032fc:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01032fe:	ff 75 10             	pushl  0x10(%ebp)
f0103301:	ff 75 0c             	pushl  0xc(%ebp)
f0103304:	ff 75 08             	pushl  0x8(%ebp)
f0103307:	e8 87 ff ff ff       	call   f0103293 <memmove>
}
f010330c:	c9                   	leave  
f010330d:	c3                   	ret    

f010330e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010330e:	55                   	push   %ebp
f010330f:	89 e5                	mov    %esp,%ebp
f0103311:	56                   	push   %esi
f0103312:	53                   	push   %ebx
f0103313:	8b 45 08             	mov    0x8(%ebp),%eax
f0103316:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103319:	89 c6                	mov    %eax,%esi
f010331b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010331e:	eb 1a                	jmp    f010333a <memcmp+0x2c>
		if (*s1 != *s2)
f0103320:	0f b6 08             	movzbl (%eax),%ecx
f0103323:	0f b6 1a             	movzbl (%edx),%ebx
f0103326:	38 d9                	cmp    %bl,%cl
f0103328:	74 0a                	je     f0103334 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010332a:	0f b6 c1             	movzbl %cl,%eax
f010332d:	0f b6 db             	movzbl %bl,%ebx
f0103330:	29 d8                	sub    %ebx,%eax
f0103332:	eb 0f                	jmp    f0103343 <memcmp+0x35>
		s1++, s2++;
f0103334:	83 c0 01             	add    $0x1,%eax
f0103337:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010333a:	39 f0                	cmp    %esi,%eax
f010333c:	75 e2                	jne    f0103320 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010333e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103343:	5b                   	pop    %ebx
f0103344:	5e                   	pop    %esi
f0103345:	5d                   	pop    %ebp
f0103346:	c3                   	ret    

f0103347 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103347:	55                   	push   %ebp
f0103348:	89 e5                	mov    %esp,%ebp
f010334a:	53                   	push   %ebx
f010334b:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010334e:	89 c1                	mov    %eax,%ecx
f0103350:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103353:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103357:	eb 0a                	jmp    f0103363 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103359:	0f b6 10             	movzbl (%eax),%edx
f010335c:	39 da                	cmp    %ebx,%edx
f010335e:	74 07                	je     f0103367 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103360:	83 c0 01             	add    $0x1,%eax
f0103363:	39 c8                	cmp    %ecx,%eax
f0103365:	72 f2                	jb     f0103359 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103367:	5b                   	pop    %ebx
f0103368:	5d                   	pop    %ebp
f0103369:	c3                   	ret    

f010336a <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010336a:	55                   	push   %ebp
f010336b:	89 e5                	mov    %esp,%ebp
f010336d:	57                   	push   %edi
f010336e:	56                   	push   %esi
f010336f:	53                   	push   %ebx
f0103370:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103373:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103376:	eb 03                	jmp    f010337b <strtol+0x11>
		s++;
f0103378:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010337b:	0f b6 01             	movzbl (%ecx),%eax
f010337e:	3c 20                	cmp    $0x20,%al
f0103380:	74 f6                	je     f0103378 <strtol+0xe>
f0103382:	3c 09                	cmp    $0x9,%al
f0103384:	74 f2                	je     f0103378 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103386:	3c 2b                	cmp    $0x2b,%al
f0103388:	75 0a                	jne    f0103394 <strtol+0x2a>
		s++;
f010338a:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010338d:	bf 00 00 00 00       	mov    $0x0,%edi
f0103392:	eb 11                	jmp    f01033a5 <strtol+0x3b>
f0103394:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103399:	3c 2d                	cmp    $0x2d,%al
f010339b:	75 08                	jne    f01033a5 <strtol+0x3b>
		s++, neg = 1;
f010339d:	83 c1 01             	add    $0x1,%ecx
f01033a0:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01033a5:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01033ab:	75 15                	jne    f01033c2 <strtol+0x58>
f01033ad:	80 39 30             	cmpb   $0x30,(%ecx)
f01033b0:	75 10                	jne    f01033c2 <strtol+0x58>
f01033b2:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01033b6:	75 7c                	jne    f0103434 <strtol+0xca>
		s += 2, base = 16;
f01033b8:	83 c1 02             	add    $0x2,%ecx
f01033bb:	bb 10 00 00 00       	mov    $0x10,%ebx
f01033c0:	eb 16                	jmp    f01033d8 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01033c2:	85 db                	test   %ebx,%ebx
f01033c4:	75 12                	jne    f01033d8 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01033c6:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01033cb:	80 39 30             	cmpb   $0x30,(%ecx)
f01033ce:	75 08                	jne    f01033d8 <strtol+0x6e>
		s++, base = 8;
f01033d0:	83 c1 01             	add    $0x1,%ecx
f01033d3:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01033d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01033dd:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01033e0:	0f b6 11             	movzbl (%ecx),%edx
f01033e3:	8d 72 d0             	lea    -0x30(%edx),%esi
f01033e6:	89 f3                	mov    %esi,%ebx
f01033e8:	80 fb 09             	cmp    $0x9,%bl
f01033eb:	77 08                	ja     f01033f5 <strtol+0x8b>
			dig = *s - '0';
f01033ed:	0f be d2             	movsbl %dl,%edx
f01033f0:	83 ea 30             	sub    $0x30,%edx
f01033f3:	eb 22                	jmp    f0103417 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01033f5:	8d 72 9f             	lea    -0x61(%edx),%esi
f01033f8:	89 f3                	mov    %esi,%ebx
f01033fa:	80 fb 19             	cmp    $0x19,%bl
f01033fd:	77 08                	ja     f0103407 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01033ff:	0f be d2             	movsbl %dl,%edx
f0103402:	83 ea 57             	sub    $0x57,%edx
f0103405:	eb 10                	jmp    f0103417 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103407:	8d 72 bf             	lea    -0x41(%edx),%esi
f010340a:	89 f3                	mov    %esi,%ebx
f010340c:	80 fb 19             	cmp    $0x19,%bl
f010340f:	77 16                	ja     f0103427 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103411:	0f be d2             	movsbl %dl,%edx
f0103414:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103417:	3b 55 10             	cmp    0x10(%ebp),%edx
f010341a:	7d 0b                	jge    f0103427 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010341c:	83 c1 01             	add    $0x1,%ecx
f010341f:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103423:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103425:	eb b9                	jmp    f01033e0 <strtol+0x76>

	if (endptr)
f0103427:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010342b:	74 0d                	je     f010343a <strtol+0xd0>
		*endptr = (char *) s;
f010342d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103430:	89 0e                	mov    %ecx,(%esi)
f0103432:	eb 06                	jmp    f010343a <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103434:	85 db                	test   %ebx,%ebx
f0103436:	74 98                	je     f01033d0 <strtol+0x66>
f0103438:	eb 9e                	jmp    f01033d8 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010343a:	89 c2                	mov    %eax,%edx
f010343c:	f7 da                	neg    %edx
f010343e:	85 ff                	test   %edi,%edi
f0103440:	0f 45 c2             	cmovne %edx,%eax
}
f0103443:	5b                   	pop    %ebx
f0103444:	5e                   	pop    %esi
f0103445:	5f                   	pop    %edi
f0103446:	5d                   	pop    %ebp
f0103447:	c3                   	ret    
f0103448:	66 90                	xchg   %ax,%ax
f010344a:	66 90                	xchg   %ax,%ax
f010344c:	66 90                	xchg   %ax,%ax
f010344e:	66 90                	xchg   %ax,%ax

f0103450 <__udivdi3>:
f0103450:	55                   	push   %ebp
f0103451:	57                   	push   %edi
f0103452:	56                   	push   %esi
f0103453:	53                   	push   %ebx
f0103454:	83 ec 1c             	sub    $0x1c,%esp
f0103457:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010345b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010345f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103463:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103467:	85 f6                	test   %esi,%esi
f0103469:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010346d:	89 ca                	mov    %ecx,%edx
f010346f:	89 f8                	mov    %edi,%eax
f0103471:	75 3d                	jne    f01034b0 <__udivdi3+0x60>
f0103473:	39 cf                	cmp    %ecx,%edi
f0103475:	0f 87 c5 00 00 00    	ja     f0103540 <__udivdi3+0xf0>
f010347b:	85 ff                	test   %edi,%edi
f010347d:	89 fd                	mov    %edi,%ebp
f010347f:	75 0b                	jne    f010348c <__udivdi3+0x3c>
f0103481:	b8 01 00 00 00       	mov    $0x1,%eax
f0103486:	31 d2                	xor    %edx,%edx
f0103488:	f7 f7                	div    %edi
f010348a:	89 c5                	mov    %eax,%ebp
f010348c:	89 c8                	mov    %ecx,%eax
f010348e:	31 d2                	xor    %edx,%edx
f0103490:	f7 f5                	div    %ebp
f0103492:	89 c1                	mov    %eax,%ecx
f0103494:	89 d8                	mov    %ebx,%eax
f0103496:	89 cf                	mov    %ecx,%edi
f0103498:	f7 f5                	div    %ebp
f010349a:	89 c3                	mov    %eax,%ebx
f010349c:	89 d8                	mov    %ebx,%eax
f010349e:	89 fa                	mov    %edi,%edx
f01034a0:	83 c4 1c             	add    $0x1c,%esp
f01034a3:	5b                   	pop    %ebx
f01034a4:	5e                   	pop    %esi
f01034a5:	5f                   	pop    %edi
f01034a6:	5d                   	pop    %ebp
f01034a7:	c3                   	ret    
f01034a8:	90                   	nop
f01034a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034b0:	39 ce                	cmp    %ecx,%esi
f01034b2:	77 74                	ja     f0103528 <__udivdi3+0xd8>
f01034b4:	0f bd fe             	bsr    %esi,%edi
f01034b7:	83 f7 1f             	xor    $0x1f,%edi
f01034ba:	0f 84 98 00 00 00    	je     f0103558 <__udivdi3+0x108>
f01034c0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01034c5:	89 f9                	mov    %edi,%ecx
f01034c7:	89 c5                	mov    %eax,%ebp
f01034c9:	29 fb                	sub    %edi,%ebx
f01034cb:	d3 e6                	shl    %cl,%esi
f01034cd:	89 d9                	mov    %ebx,%ecx
f01034cf:	d3 ed                	shr    %cl,%ebp
f01034d1:	89 f9                	mov    %edi,%ecx
f01034d3:	d3 e0                	shl    %cl,%eax
f01034d5:	09 ee                	or     %ebp,%esi
f01034d7:	89 d9                	mov    %ebx,%ecx
f01034d9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034dd:	89 d5                	mov    %edx,%ebp
f01034df:	8b 44 24 08          	mov    0x8(%esp),%eax
f01034e3:	d3 ed                	shr    %cl,%ebp
f01034e5:	89 f9                	mov    %edi,%ecx
f01034e7:	d3 e2                	shl    %cl,%edx
f01034e9:	89 d9                	mov    %ebx,%ecx
f01034eb:	d3 e8                	shr    %cl,%eax
f01034ed:	09 c2                	or     %eax,%edx
f01034ef:	89 d0                	mov    %edx,%eax
f01034f1:	89 ea                	mov    %ebp,%edx
f01034f3:	f7 f6                	div    %esi
f01034f5:	89 d5                	mov    %edx,%ebp
f01034f7:	89 c3                	mov    %eax,%ebx
f01034f9:	f7 64 24 0c          	mull   0xc(%esp)
f01034fd:	39 d5                	cmp    %edx,%ebp
f01034ff:	72 10                	jb     f0103511 <__udivdi3+0xc1>
f0103501:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103505:	89 f9                	mov    %edi,%ecx
f0103507:	d3 e6                	shl    %cl,%esi
f0103509:	39 c6                	cmp    %eax,%esi
f010350b:	73 07                	jae    f0103514 <__udivdi3+0xc4>
f010350d:	39 d5                	cmp    %edx,%ebp
f010350f:	75 03                	jne    f0103514 <__udivdi3+0xc4>
f0103511:	83 eb 01             	sub    $0x1,%ebx
f0103514:	31 ff                	xor    %edi,%edi
f0103516:	89 d8                	mov    %ebx,%eax
f0103518:	89 fa                	mov    %edi,%edx
f010351a:	83 c4 1c             	add    $0x1c,%esp
f010351d:	5b                   	pop    %ebx
f010351e:	5e                   	pop    %esi
f010351f:	5f                   	pop    %edi
f0103520:	5d                   	pop    %ebp
f0103521:	c3                   	ret    
f0103522:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103528:	31 ff                	xor    %edi,%edi
f010352a:	31 db                	xor    %ebx,%ebx
f010352c:	89 d8                	mov    %ebx,%eax
f010352e:	89 fa                	mov    %edi,%edx
f0103530:	83 c4 1c             	add    $0x1c,%esp
f0103533:	5b                   	pop    %ebx
f0103534:	5e                   	pop    %esi
f0103535:	5f                   	pop    %edi
f0103536:	5d                   	pop    %ebp
f0103537:	c3                   	ret    
f0103538:	90                   	nop
f0103539:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103540:	89 d8                	mov    %ebx,%eax
f0103542:	f7 f7                	div    %edi
f0103544:	31 ff                	xor    %edi,%edi
f0103546:	89 c3                	mov    %eax,%ebx
f0103548:	89 d8                	mov    %ebx,%eax
f010354a:	89 fa                	mov    %edi,%edx
f010354c:	83 c4 1c             	add    $0x1c,%esp
f010354f:	5b                   	pop    %ebx
f0103550:	5e                   	pop    %esi
f0103551:	5f                   	pop    %edi
f0103552:	5d                   	pop    %ebp
f0103553:	c3                   	ret    
f0103554:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103558:	39 ce                	cmp    %ecx,%esi
f010355a:	72 0c                	jb     f0103568 <__udivdi3+0x118>
f010355c:	31 db                	xor    %ebx,%ebx
f010355e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103562:	0f 87 34 ff ff ff    	ja     f010349c <__udivdi3+0x4c>
f0103568:	bb 01 00 00 00       	mov    $0x1,%ebx
f010356d:	e9 2a ff ff ff       	jmp    f010349c <__udivdi3+0x4c>
f0103572:	66 90                	xchg   %ax,%ax
f0103574:	66 90                	xchg   %ax,%ax
f0103576:	66 90                	xchg   %ax,%ax
f0103578:	66 90                	xchg   %ax,%ax
f010357a:	66 90                	xchg   %ax,%ax
f010357c:	66 90                	xchg   %ax,%ax
f010357e:	66 90                	xchg   %ax,%ax

f0103580 <__umoddi3>:
f0103580:	55                   	push   %ebp
f0103581:	57                   	push   %edi
f0103582:	56                   	push   %esi
f0103583:	53                   	push   %ebx
f0103584:	83 ec 1c             	sub    $0x1c,%esp
f0103587:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010358b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010358f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103593:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103597:	85 d2                	test   %edx,%edx
f0103599:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010359d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01035a1:	89 f3                	mov    %esi,%ebx
f01035a3:	89 3c 24             	mov    %edi,(%esp)
f01035a6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01035aa:	75 1c                	jne    f01035c8 <__umoddi3+0x48>
f01035ac:	39 f7                	cmp    %esi,%edi
f01035ae:	76 50                	jbe    f0103600 <__umoddi3+0x80>
f01035b0:	89 c8                	mov    %ecx,%eax
f01035b2:	89 f2                	mov    %esi,%edx
f01035b4:	f7 f7                	div    %edi
f01035b6:	89 d0                	mov    %edx,%eax
f01035b8:	31 d2                	xor    %edx,%edx
f01035ba:	83 c4 1c             	add    $0x1c,%esp
f01035bd:	5b                   	pop    %ebx
f01035be:	5e                   	pop    %esi
f01035bf:	5f                   	pop    %edi
f01035c0:	5d                   	pop    %ebp
f01035c1:	c3                   	ret    
f01035c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01035c8:	39 f2                	cmp    %esi,%edx
f01035ca:	89 d0                	mov    %edx,%eax
f01035cc:	77 52                	ja     f0103620 <__umoddi3+0xa0>
f01035ce:	0f bd ea             	bsr    %edx,%ebp
f01035d1:	83 f5 1f             	xor    $0x1f,%ebp
f01035d4:	75 5a                	jne    f0103630 <__umoddi3+0xb0>
f01035d6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01035da:	0f 82 e0 00 00 00    	jb     f01036c0 <__umoddi3+0x140>
f01035e0:	39 0c 24             	cmp    %ecx,(%esp)
f01035e3:	0f 86 d7 00 00 00    	jbe    f01036c0 <__umoddi3+0x140>
f01035e9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01035ed:	8b 54 24 04          	mov    0x4(%esp),%edx
f01035f1:	83 c4 1c             	add    $0x1c,%esp
f01035f4:	5b                   	pop    %ebx
f01035f5:	5e                   	pop    %esi
f01035f6:	5f                   	pop    %edi
f01035f7:	5d                   	pop    %ebp
f01035f8:	c3                   	ret    
f01035f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103600:	85 ff                	test   %edi,%edi
f0103602:	89 fd                	mov    %edi,%ebp
f0103604:	75 0b                	jne    f0103611 <__umoddi3+0x91>
f0103606:	b8 01 00 00 00       	mov    $0x1,%eax
f010360b:	31 d2                	xor    %edx,%edx
f010360d:	f7 f7                	div    %edi
f010360f:	89 c5                	mov    %eax,%ebp
f0103611:	89 f0                	mov    %esi,%eax
f0103613:	31 d2                	xor    %edx,%edx
f0103615:	f7 f5                	div    %ebp
f0103617:	89 c8                	mov    %ecx,%eax
f0103619:	f7 f5                	div    %ebp
f010361b:	89 d0                	mov    %edx,%eax
f010361d:	eb 99                	jmp    f01035b8 <__umoddi3+0x38>
f010361f:	90                   	nop
f0103620:	89 c8                	mov    %ecx,%eax
f0103622:	89 f2                	mov    %esi,%edx
f0103624:	83 c4 1c             	add    $0x1c,%esp
f0103627:	5b                   	pop    %ebx
f0103628:	5e                   	pop    %esi
f0103629:	5f                   	pop    %edi
f010362a:	5d                   	pop    %ebp
f010362b:	c3                   	ret    
f010362c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103630:	8b 34 24             	mov    (%esp),%esi
f0103633:	bf 20 00 00 00       	mov    $0x20,%edi
f0103638:	89 e9                	mov    %ebp,%ecx
f010363a:	29 ef                	sub    %ebp,%edi
f010363c:	d3 e0                	shl    %cl,%eax
f010363e:	89 f9                	mov    %edi,%ecx
f0103640:	89 f2                	mov    %esi,%edx
f0103642:	d3 ea                	shr    %cl,%edx
f0103644:	89 e9                	mov    %ebp,%ecx
f0103646:	09 c2                	or     %eax,%edx
f0103648:	89 d8                	mov    %ebx,%eax
f010364a:	89 14 24             	mov    %edx,(%esp)
f010364d:	89 f2                	mov    %esi,%edx
f010364f:	d3 e2                	shl    %cl,%edx
f0103651:	89 f9                	mov    %edi,%ecx
f0103653:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103657:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010365b:	d3 e8                	shr    %cl,%eax
f010365d:	89 e9                	mov    %ebp,%ecx
f010365f:	89 c6                	mov    %eax,%esi
f0103661:	d3 e3                	shl    %cl,%ebx
f0103663:	89 f9                	mov    %edi,%ecx
f0103665:	89 d0                	mov    %edx,%eax
f0103667:	d3 e8                	shr    %cl,%eax
f0103669:	89 e9                	mov    %ebp,%ecx
f010366b:	09 d8                	or     %ebx,%eax
f010366d:	89 d3                	mov    %edx,%ebx
f010366f:	89 f2                	mov    %esi,%edx
f0103671:	f7 34 24             	divl   (%esp)
f0103674:	89 d6                	mov    %edx,%esi
f0103676:	d3 e3                	shl    %cl,%ebx
f0103678:	f7 64 24 04          	mull   0x4(%esp)
f010367c:	39 d6                	cmp    %edx,%esi
f010367e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103682:	89 d1                	mov    %edx,%ecx
f0103684:	89 c3                	mov    %eax,%ebx
f0103686:	72 08                	jb     f0103690 <__umoddi3+0x110>
f0103688:	75 11                	jne    f010369b <__umoddi3+0x11b>
f010368a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010368e:	73 0b                	jae    f010369b <__umoddi3+0x11b>
f0103690:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103694:	1b 14 24             	sbb    (%esp),%edx
f0103697:	89 d1                	mov    %edx,%ecx
f0103699:	89 c3                	mov    %eax,%ebx
f010369b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010369f:	29 da                	sub    %ebx,%edx
f01036a1:	19 ce                	sbb    %ecx,%esi
f01036a3:	89 f9                	mov    %edi,%ecx
f01036a5:	89 f0                	mov    %esi,%eax
f01036a7:	d3 e0                	shl    %cl,%eax
f01036a9:	89 e9                	mov    %ebp,%ecx
f01036ab:	d3 ea                	shr    %cl,%edx
f01036ad:	89 e9                	mov    %ebp,%ecx
f01036af:	d3 ee                	shr    %cl,%esi
f01036b1:	09 d0                	or     %edx,%eax
f01036b3:	89 f2                	mov    %esi,%edx
f01036b5:	83 c4 1c             	add    $0x1c,%esp
f01036b8:	5b                   	pop    %ebx
f01036b9:	5e                   	pop    %esi
f01036ba:	5f                   	pop    %edi
f01036bb:	5d                   	pop    %ebp
f01036bc:	c3                   	ret    
f01036bd:	8d 76 00             	lea    0x0(%esi),%esi
f01036c0:	29 f9                	sub    %edi,%ecx
f01036c2:	19 d6                	sbb    %edx,%esi
f01036c4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01036c8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01036cc:	e9 18 ff ff ff       	jmp    f01035e9 <__umoddi3+0x69>
