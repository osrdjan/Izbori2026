from pathlib import Path
import json,re
import pymupdf
from PIL import Image,ImageDraw,ImageFont
root=Path(__file__).resolve().parent.parent
out=root/'obrada_2026'
files=json.loads((out/'main_files.json').read_text(encoding='utf-8'))
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20)
for batch in range(0,len(files),8):
    sheet=Image.new('RGB',(8*280,1390),'white'); draw=ImageDraw.Draw(sheet)
    for k,file in enumerate(files[batch:batch+8]):
        p=root/file; doc=pymupdf.open(p)
        page=doc[0]; pix=page.get_pixmap(dpi=150)
        im=Image.frombytes('RGB',[pix.width,pix.height],pix.samples)
        im.save(out/('full_'+('SE' if 'СЕВОЈНО' in p.name else 'UZ')+re.search(r'\d+',p.name)[0]+'.png'))
        w,h=im.size
        def crop(box,target):
            a=im.crop(tuple(int(v*(w if i%2==0 else h)) for i,v in enumerate(box)))
            a.thumbnail(target)
            return a
        x=k*280
        draw.text((x+8,5),('SE' if 'СЕВОЈНО' in p.name else 'UZ')+' '+re.search(r'\d+',p.name)[0],font=font,fill='black')
        draw.text((x+5,37),'registered (4)',font=font,fill='black')
        sheet.paste(crop((.24,.27,.48,.40),(270,125)),(x+5,64))
        draw.text((x+5,165),'turnout/box/invalid/valid',font=font,fill='black')
        sheet.paste(crop((.32,.74,.48,.94),(265,245)),(x+5,196))
        draw.text((x+5,450),'votes, lists 1-18',font=font,fill='black')
        sheet.paste(crop((.82,.09,.985,.66),(270,900)),(x+5,480))
        draw.line((x+278,0,x+278,1390),fill='#777777')
    sheet.save(out/('sheet_%02d.png'%(batch//8+1)))
