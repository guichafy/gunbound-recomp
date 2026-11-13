
/Users/guichafy/Workspaces/DemoGame/.tools/gunbound-client/GunBound.gme:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  43f108: 8b 0d 84 34 5b 00            	movl	0x5b3484, %ecx
  43f10e: 0f b6 81 c4 75 04 00         	movzbl	0x475c4(%ecx), %eax
  43f115: 69 c0 28 7d 00 00            	imull	$0x7d28, %eax, %eax     # imm = 0x7D28
  43f11b: 8d 84 08 c8 1e 1a 00         	leal	0x1a1ec8(%eax,%ecx), %eax
  43f122: 68 b1 1c 55 00               	pushl	$0x551cb1               # imm = 0x551CB1
  43f127: 81 c1 08 77 6a 00            	addl	$0x6a7708, %ecx         # imm = 0x6A7708
  43f12d: 51                           	pushl	%ecx
  43f12e: e8 2d 4c 0a 00               	calll	0x4e3d60 <.text+0xe2d60>
  43f133: 55                           	pushl	%ebp
  43f134: e8 87 3f 00 00               	calll	0x4430c0 <.text+0x420c0>
  43f139: a1 84 34 5b 00               	movl	0x5b3484, %eax
  43f13e: 0f b6 88 c4 75 04 00         	movzbl	0x475c4(%eax), %ecx
  43f145: 69 c9 28 7d 00 00            	imull	$0x7d28, %ecx, %ecx     # imm = 0x7D28
  43f14b: 8d 94 01 c8 1e 1a 00         	leal	0x1a1ec8(%ecx,%eax), %edx
  43f152: 52                           	pushl	%edx
  43f153: 8d 44 24 14                  	leal	0x14(%esp), %eax
  43f157: 68 00 55 55 00               	pushl	$0x555500               # imm = 0x555500
  43f15c: 50                           	pushl	%eax
  43f15d: e8 7c 64 0e 00               	calll	0x5255de <.text+0x1245de>
  43f162: 8b 0d 84 34 5b 00            	movl	0x5b3484, %ecx
  43f168: 83 c4 0c                     	addl	$0xc, %esp
  43f16b: 81 c1 70 ec 67 00            	addl	$0x67ec70, %ecx         # imm = 0x67EC70
  43f171: 51                           	pushl	%ecx
  43f172: 8d 44 24 14                  	leal	0x14(%esp), %eax
  43f176: e8 c5 25 fc ff               	calll	0x401740 <.text+0x740>
  43f17b: 8b 1d 84 34 5b 00            	movl	0x5b3484, %ebx
  43f181: 8d 54 24 10                  	leal	0x10(%esp), %edx
  43f185: 52                           	pushl	%edx
  43f186: 81 c3 70 ec 67 00            	addl	$0x67ec70, %ebx         # imm = 0x67EC70
  43f18c: e8 3f 26 fc ff               	calll	0x4017d0 <.text+0x7d0>
  43f191: 8b 0d 84 34 5b 00            	movl	0x5b3484, %ecx
  43f197: 8d 7c 24 10                  	leal	0x10(%esp), %edi
  43f19b: 89 81 70 7f 6a 00            	movl	%eax, 0x6a7f70(%ecx)
  43f1a1: 4f                           	decl	%edi
  43f1a2: 8a 47 01                     	movb	0x1(%edi), %al
  43f1a5: 47                           	incl	%edi
  43f1a6: 84 c0                        	testb	%al, %al
  43f1a8: 75 f8                        	jne	0x43f1a2 <.text+0x3e1a2>
  43f1aa: 8b 15 f8 54 55 00            	movl	0x5554f8, %edx
  43f1b0: a0 fc 54 55 00               	movb	0x5554fc, %al
  43f1b5: 89 17                        	movl	%edx, (%edi)
  43f1b7: 68 14 1e 00 00               	pushl	$0x1e14                 # imm = 0x1E14
  43f1bc: 88 47 04                     	movb	%al, 0x4(%edi)
  43f1bf: 68 18 0e ea 00               	pushl	$0xea0e18               # imm = 0xEA0E18
  43f1c4: 8d 44 24 18                  	leal	0x18(%esp), %eax
  43f1c8: e8 c3 25 0b 00               	calll	0x4f1790 <.text+0xf0790>
  43f1cd: a1 84 34 5b 00               	movl	0x5b3484, %eax
  43f1d2: 0f b6 88 c4 75 04 00         	movzbl	0x475c4(%eax), %ecx
  43f1d9: 69 c9 28 7d 00 00            	imull	$0x7d28, %ecx, %ecx     # imm = 0x7D28
  43f1df: 8d 94 01 8c 32 1a 00         	leal	0x1a328c(%ecx,%eax), %edx
  43f1e6: 52                           	pushl	%edx
  43f1e7: e8 e4 b2 fc ff               	calll	0x40a4d0 <.text+0x94d0>
  43f1ec: a3 34 36 79 00               	movl	%eax, 0x793634
  43f1f1: e9 1f 2e 00 00               	jmp	0x442015 <.text+0x41015>
  43f1f6: a1 84 34 5b 00               	movl	0x5b3484, %eax
  43f1fb: 0f b6 88 c4 75 04 00         	movzbl	0x475c4(%eax), %ecx
  43f202: 69 c9 28 7d 00 00            	imull	$0x7d28, %ecx, %ecx     # imm = 0x7D28
  43f208: 8d 94 01 c8 1e 1a 00         	leal	0x1a1ec8(%ecx,%eax), %edx
  43f20f: 52                           	pushl	%edx
  43f210: e8 fb 4d 0a 00               	calll	0x4e4010 <.text+0xe3010>
  43f215: e9 fb 2d 00 00               	jmp	0x442015 <.text+0x41015>
  43f21a: 8b 0d 84 34 5b 00            	movl	0x5b3484, %ecx
  43f220: 0f b6 81 c4 75 04 00         	movzbl	0x475c4(%ecx), %eax
  43f227: 69 c0 28 7d 00 00            	imull	$0x7d28, %eax, %eax     # imm = 0x7D28
  43f22d: 8d 84 08 c8 1e 1a 00         	leal	0x1a1ec8(%eax,%ecx), %eax
  43f234: 81 c1 08 77 6a 00            	addl	$0x6a7708, %ecx         # imm = 0x6A7708
  43f23a: 51                           	pushl	%ecx
  43f23b: e8 10 4a 0a 00               	calll	0x4e3c50 <.text+0xe2c50>
