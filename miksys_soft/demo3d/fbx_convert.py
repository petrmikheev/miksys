#!/usr/bin/python3

import re,math

data = open('house.fbx').read()
scale_coef = 70*16

def vhash(v):
    x, y, z = v[0], v[1], v[2]
    return (x*31+y)*17+z

def vsub(v1, v2):
    return (v1[0]-v2[0], v1[1]-v2[1], v1[2]-v2[2])

def vprod(v1, v2):
    x1,y1,z1=v1
    x2,y2,z2=v2
    x = y1*z2-y2*z1
    y = z1*x2-x1*z2
    z = x1*y2-y1*x2
    s = math.sqrt(x**2 + y**2 + z**2)
    return (x/s, y/s, z/s)

materials = {}
vertices = []
v_hash = {}
faces = []

for m, c in re.findall(r'Material: "(Material::\w+)"|Property: "DiffuseColor", "ColorRGB", "",(.*)', data):
    if m!='':
        cm = m
        continue
    else:
        materials[cm] = [float(x) for x in c.split(',')]

ctitle = ''
for p in re.split('Model: "([\w:]+)"', data):
    if p.startswith('Model::'):
        ctitle = p
        continue
    match_vertices = re.search(r'Vertices:([\d\s\.,-]*)', p)
    match_faces = re.search(r'PolygonVertexIndex:([\d\s\.,-]*)', p)
    if (match_vertices is None) or (match_faces is None): continue
    verts = [float(x) for x in match_vertices.group(1).split(',')]
    faces_vi = [int(x) for x in match_faces.group(1).split(',')]
    verts = [(int(verts[i*3]*scale_coef), int(verts[i*3+1]*scale_coef), int(verts[i*3+2]*scale_coef), False, 0, 0, '') for i in range(len(verts)//3)]
    mat = re.search('Connect: "OO", "(Material::\w+)", "%s"' % ctitle, data).group(1)
    material_s = 'MATERIAL_' + mat[10:].split('_')[0]
    match_uv = re.search(r'\sUV:([\d\s\.,-]*)', p)
    match_uv_index = re.search(r'UVIndex:([\d\s\.,-]*)', p)
    if match_uv != None:
        uv = [float(x) for x in match_uv.group(1).split(',')]
        uv_index = [int(x) for x in match_uv_index.group(1).split(',')]
        for i in range(len(faces_vi)):
            v = faces_vi[i]
            if v<0: v = -v-1
            j = uv_index[i]
            verts[v] = verts[v][:3] + (True, int(round(uv[j*2]*64)), int(round(uv[j*2+1]*64)), material_s)
    vdict = {}
    i = 0
    for v in verts:
        h = vhash(v)
        if (h in v_hash) and not (vertices[v_hash[h]][3] and v[3]):
            vdict[i] = v_hash[h]
            if v[3]: vertices[vdict[i]] = v
        else:
            vertices.append(v)
            v_hash[h] = vdict[i] = len(vertices)-1
        i+=1
    
    tmp = []
    for x in faces_vi:
        if x >= 0:
            tmp.append(x)
        else:
            tmp.append(-x-1)
            if len(tmp)>2:
                v1, v2, v3 = vdict[tmp[0]], vdict[tmp[1]], vdict[tmp[2]]
                p1, p2, p3 = vertices[v1], vertices[v2], vertices[v3]
                n = vprod(vsub(p2, p1), vsub(p3, p1))
                e = n[0]*0.7 - n[1]*0.3 + n[2]*0.5
                if e<0: e /= 4
                e = (e+1) * 0.8
                if match_uv is None:
                    rgb = materials[mat]
                    r = min(31,int(rgb[0]*e*31+0.5))
                    g = min(31, int(rgb[1]*e*31+0.5))
                    b = min(31, int(rgb[2]*e*31+0.5))
                    material_s = 'RGB("%d %d %d")' % (r, g, b)
                else:
                    material_s = '(%d*0x20)|MATERIAL_' % min(15, int(e*8+0.5)) + mat[10:].split('_')[0]
                faces += [(vdict[tmp[0]], vdict[tmp[i+1]], vdict[tmp[i+2]], material_s) for i in range(len(tmp)-2)]
            tmp = []

print('#define V(x) (VERTICES_BUF + x*5)')
print('.data 0x0 MEMORY_FACES_OFFSET')
i = 0
for f in faces:
    print('    .const V(%3d), V(%3d), V(%3d), %s // %d' % (f[0], f[1], f[2], f[3], i))
    i += 1
print('faces_list_end:\n')
print('.data 0x0 MEMORY_VERTICES_OFFSET')
i = 0
for v in vertices:
    x = v[0]-50*16
    y = v[2]-100*16
    z = v[1]
    if v[6]=='':
        print('    .const %4d, %4d, %4d, %4d, %4d // %d' % (x, y, z, v[4], v[5], i))
    else:
        print('    .const %4d, %4d, %4d, %4d/(2-(%s>>4)%%2), %4d/(2-(%s>>3)%%2) // %d' % (x, y, z, v[4], v[6], v[5], v[6], i))
    i += 1
print('vertices_list_end:\n\n.data 0x0 MEMORY_TEXTURES_OFFSET')

