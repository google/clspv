// RUN: clspv %s -o %t.spv
// RUN: spirv-val --target-env vulkan1.0 %t.spv

static void load_data(global int* buffer, int* data, int end)
{
	for (int i = 0; i < end; ++i)
	{
		data[i] = buffer[i];
		data[i] = buffer[i];
		buffer += 2;
		data += 2;
	}
}

kernel void test(global int* buffer, constant int* ends)
{
	int data[16];
	load_data(buffer, data, *ends);
}
