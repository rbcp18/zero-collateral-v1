let scores: any
export default scores = {
  // this is a good score as the first array element of each array has a hex value of 10
  // the rest of the elements is the mock secret provided by the provider
  good: [
    [
      '0x0000000a',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000001',
    ],
    [
      '0x0000000a',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000002',
    ],
    [
      '0x0000000a',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000003',
    ],
  ],
  // this is a good score as the first array element of each array has a hex value of 3
  // the rest of the elements is the mock secret provided by the provider
  bad: [
    [
      '0x00000003',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000001',
    ],
    [
      '0x00000003',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000002',
    ],
    [
      '0x00000003',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000000',
      '0x00000003',
    ],
  ],
}
