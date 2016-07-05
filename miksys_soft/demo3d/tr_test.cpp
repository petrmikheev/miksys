#include <cstdio>
#include <cstring>
#include <stdint.h>
#include <algorithm>

using namespace std;

const int WIDTH = 640;
const int HEIGHT = 480;

unsigned short color_buf[WIDTH * HEIGHT];
unsigned short color_line[WIDTH];
short depth_line[WIDTH];

struct Vertex {
    short x, y, z, u, v;
    Vertex(short x, short y) { this->x = x; this->y = y; z = u = v = 0; }
};

const Vertex vertices[] = {
    Vertex(300, 100), Vertex(200, 200), Vertex(300, 200), Vertex(400, 200), Vertex(200, 300), Vertex(300, 300)
};

struct Face {
    short v1, v2, v3, type;
    Face(short v1, short v2, short v3, short type = 0) { this->v1 = v1; this->v2 = v2; this->v3 = v3; this->type = type; }
    bool operator<(const Face f) const {
        const Vertex& a = vertices[v1];
        const Vertex& b = vertices[f.v1];
        //if (a.y == b.y)
        //    return a.x < b.x;
        //else
            return a.y < b.y;
    }
};

Face faces[] = { Face(0, 1, 3), Face(1, 5, 2), Face(1, 4, 5) };

const short vertices_count = sizeof(vertices) / sizeof(Vertex);
short faces_count = sizeof(faces) / sizeof(Face);

void sort_faces_points() {
    for (int i = 0; i < faces_count; ++i) {
        Face& f = faces[i];
        const Vertex& v1 = vertices[f.v1];
        const Vertex& v2 = vertices[f.v2];
        const Vertex& v3 = vertices[f.v3];
        int vec_prod = (int)(v2.x - v1.x) * (v3.y - v1.y) - (int)(v3.x - v1.x) * (v2.y - v1.y);
        bool del = vec_prod > 0;
        if (v1.x < 0 && v2.x < 0 && v3.x < 0) del = true;
        if (v1.y < 0 && v2.y < 0 && v3.y < 0) del = true;
        if (v1.x >= WIDTH && v2.x >= WIDTH && v3.x >= WIDTH) del = true;
        if (v1.y >= HEIGHT && v2.y >= HEIGHT && v3.x >= HEIGHT) del = true;
        if (del) {
            Face& lf = faces[faces_count - 1];
            f.v1 = lf.v1;
            f.v2 = lf.v2;
            f.v3 = lf.v3;
            f.type = lf.type;
            faces_count--;
            i--;
            continue;
        }
        if (v2.y < v1.y && v2.y <= v3.y) {
            short o = f.v1;
            f.v1 = f.v2;
            f.v2 = f.v3;
            f.v3 = o;
        } else if (v3.y < v1.y) {
            short o = f.v3;
            f.v3 = f.v2;
            f.v2 = f.v1;
            f.v1 = o;
        }
    }
}

Vertex average(const Vertex v1, const Vertex v2, short y) {
    Vertex ans = v1;
    short frac2 = v2.y - v1.y;
    if (frac2 == 0) return ans;
    short frac1 = y - v1.y;
    ans.x += ((int)(v2.x - v1.x) * frac1) / frac2;
    ans.z += ((int)(v2.z - v1.z) * frac1) / frac2;
    ans.u += ((int)(v2.u - v1.u) * frac1) / frac2;
    ans.v += ((int)(v2.v - v1.v) * frac1) / frac2;
    return ans;
}

void fill_buffer_simple();
void fill_buffer() {
    sort_faces_points();
    //sort(faces, faces + faces_count);
    for (int y = 0; y < HEIGHT; ++y) {
        for (int x = 0; x < WIDTH; ++x) {
            color_line[x] = 0;
            depth_line[x] = 0x7fff;
        }
        for (int face_id = 0; face_id < faces_count; ++face_id) {
            const Face& f = faces[face_id];
            const Vertex& v1 = vertices[f.v1];
            const Vertex& v2 = vertices[f.v2];
            const Vertex& v3 = vertices[f.v3];
            if (v1.y > y || (v2.y < y && v3.y < y)) continue;
            Vertex va(0, 0), vb(0, 0);
            if (y <= v2.y)
                va = average(v1, v2, y);
            else
                va = average(v2, v3, y);
            if (y <= v3.y)
                vb = average(v1, v3, y);
            else
                vb = average(v3, v2, y);
            
            int denom = 0x10000;
            if (vb.x != va.x) denom /= (vb.x - va.x);
            int sz = (vb.z - va.z) * denom;
            int su = (vb.u - va.u) * denom;
            int sv = (vb.v - va.v) * denom;
            int s = 0;
            if (va.x < 0) {
                s = -va.x;
                va.x = 0;
            }
            if (vb.x >= WIDTH) vb.x = WIDTH - 1;
            for (int x = va.x; x <= vb.x; ++x) {
                short z = va.z + (short)((sz * s) >> 16);
                short u = va.u + (short)((su * s) >> 16);
                short v = va.v + (short)((sv * s) >> 16);
                //if (depth_line[x] < z) {
                    color_line[x] = 0xffff; // TODO material
                //    depth_line[x] = z;
                //}
                s++;
            }
        }
        memcpy(color_buf + y * WIDTH, color_line, WIDTH * 2);
    }
    //fill_buffer_simple();
}

bool side(int cx, int cy, int x1, int y1, int x2, int y2) {
    x1 -= cx; y1 -= cy; x2 -= cx; y2 -= cy;
    return x1 * y2 - x2 * y1 <= 0;
}

void fill_buffer_simple() {
    memset(color_buf, 0, WIDTH*HEIGHT*2);
    for (int i = 0; i < faces_count; ++i) {
        const Face& f = faces[i];
        for (int y = 0; y < HEIGHT; ++y)
            for (int x = 0; x < WIDTH; ++x) {
                const Vertex& v1 = vertices[f.v1];
                const Vertex& v2 = vertices[f.v2];
                const Vertex& v3 = vertices[f.v3];
                bool i1 = side(v1.x, v1.y, v2.x, v2.y, x, y);
                bool i2 = side(v2.x, v2.y, v3.x, v3.y, x, y);
                bool i3 = side(v3.x, v3.y, v1.x, v1.y, x, y);
                bool into = i1 == i2 && i2 == i3;
                if (into) color_buf[y * WIDTH + x] = 0xffff;
            }
    }
}

int main() {
    fill_buffer();
    FILE* bmp_file = fopen("img.bmp", "wb");
    #pragma pack(1)
    struct {
        uint16_t type; // BM
        uint32_t file_size; // data_size + 54
        uint32_t reserved; // 0
        uint32_t data_offset; // 54
        uint32_t biSize; // 40
        uint32_t biWidth;
        uint32_t biHeight;
        uint16_t biPlanes; // 1
        uint16_t bitsPerPixel; // 24
        uint32_t biCompression; // 0
        uint32_t data_size;
        uint64_t zero1;
        uint64_t zero2;
    } bmp_header;
    struct Pixel { unsigned char b,g,r; };
    #pragma pack()
    size_t data_size = WIDTH * HEIGHT * 3;
    bmp_header.type = 0x4d42;
    bmp_header.file_size = data_size + 54;
    bmp_header.reserved = bmp_header.zero1 = bmp_header.zero2 = 0;
    bmp_header.data_offset = 54;
    bmp_header.biSize = 40;
    bmp_header.biWidth = WIDTH;
    bmp_header.biHeight = HEIGHT;
    bmp_header.biPlanes = 1;
    bmp_header.bitsPerPixel = 24;
    bmp_header.biCompression = 0;
    bmp_header.data_size = data_size;
    fwrite(&bmp_header, sizeof(bmp_header), 1, bmp_file);
    Pixel* bmp_data = new Pixel[WIDTH];
    for (int y = 0; y < HEIGHT; ++y) {
        for (int x = 0; x < WIDTH; ++x) {
            unsigned short color = color_buf[(HEIGHT-y-1) * WIDTH + x];
            Pixel& p = bmp_data[x];
            p.r = ((color >> 11) & 0x1f) << 3;
            p.g = ((color >> 5) & 0x3f) << 2;
            p.b = (color & 0x1f) << 3;
        }
        fwrite(bmp_data, 3, WIDTH, bmp_file);
    }
    delete [] bmp_data;
    return 0;
}

