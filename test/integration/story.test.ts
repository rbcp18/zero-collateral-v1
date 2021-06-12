import Chai from 'chai'

import Mocha from 'mocha'
import { solidity } from 'ethereum-waffle'
import hre from 'hardhat'
import { updatePlatformSetting } from '../../tasks'
import {
  generateTests,
  STORY_ACTIONS,
  TestScenario,
  TestAction,
} from '../helpers/story/story-helpers'
import { generateStories } from '../helpers/story/generator/story-generator'
Chai.should()
Chai.use(solidity)

describe.only('story test', async () => {
  const allTestStories: Array<TestScenario> = generateStories()

  // console.log(
  //   'Generating tests for the following stories:',
  //   JSON.stringify(allTestStories)
  // )

  var allGeneratedTests: Array<any> = []

  for (let story of allTestStories) {
    let newTests = generateTests(story)

    allGeneratedTests = allGeneratedTests.concat(newTests)
  }

  // console.log('Generated tests:', JSON.stringify(allGeneratedTests))

  let Suite = Mocha.Suite
  var Test = Mocha.Test
  var expect = Chai.expect

  var mochaInstance = new Mocha({
    timeout: 10000,
  })
  var suiteInstance = Mocha.Suite.create(
    mochaInstance.suite,
    'Story Test Suite'
  )
  console.log({ tests: allGeneratedTests.length })
  // for (let test of allGeneratedTests) {
  //   suiteInstance.addTest(test)
  // }
  allGeneratedTests.map((test) => suiteInstance.addTest(test))

  //is this needed ?
  /*before(async () => {
    await updatePlatformSetting(
      {
        name: 'RequiredSubmissionsPercentage',
        value: 100,
      },
      hre
    )
  })*/

  //run all of the generated story tests (they are async)
  mochaInstance.run()
})
